import 'dart:async';

import '../../domain/models/auth_models.dart';
import '../../domain/models/search_resource.dart';
import '../../domain/models/search_result.dart';
import '../../utils/app_logger.dart';
import '../../utils/result.dart';
import '../services/api_service.dart';
import '../services/search_source_service.dart';

abstract interface class SearchRepository {
  void clearCache();
  Future<Result<List<String>>> getSuggestions(
    String query, {
    required bool localSearchEnabled,
  });
  Future<Result<List<String>>> searchRecommendations(String query);
  Future<Result<List<SearchResult>>> searchLocal(String query);
  Future<Result<List<SearchResult>>> getLocalDetail(String source, String id);
}

/// 搜索数据仓库；运行模式和偏好由调用方明确传入，不依赖其他仓库。
final class DefaultSearchRepository implements SearchRepository {
  DefaultSearchRepository({
    required ApiService apiService,
    required SessionState sessionState,
    SearchSourceService? sourceService,
  }) : _apiService = apiService,
       _sessionState = sessionState,
       _sourceService = sourceService ?? const DefaultSearchSourceService();

  final ApiService _apiService;
  final SessionState _sessionState;
  final SearchSourceService _sourceService;

  List<SearchResource>? _cachedResources;
  Future<List<SearchResource>>? _refreshingResources;
  int _cacheGeneration = 0;

  bool get _isLocalMode => _sessionState.status == AuthStatus.localMode;

  @override
  void clearCache() {
    _cacheGeneration++;
    _cachedResources = null;
    _refreshingResources = null;
  }

  @override
  Future<Result<List<String>>> getSuggestions(
    String query, {
    required bool localSearchEnabled,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return const Success<List<String>>(<String>[]);
    }
    if (_isLocalMode || localSearchEnabled) {
      return searchRecommendations(normalized);
    }
    return _guard('获取搜索建议失败', () async {
      final values = await _apiService.getSearchSuggestions(normalized);
      return values.toSet().take(8).toList(growable: false);
    });
  }

  @override
  Future<Result<List<String>>> searchRecommendations(String query) =>
      _guard('获取搜索建议失败', () async {
        final resources = await _enabledResources();
        if (resources.isEmpty) return const <String>[];
        final results = await _sourceService
            .search(resources.first, query.trim())
            .timeout(const Duration(seconds: 5));
        return results
            .map((result) => result.title)
            .toSet()
            .take(8)
            .toList(growable: false);
      });

  @override
  Future<Result<List<SearchResult>>> searchLocal(String query) =>
      _guard('本地搜索失败', () async {
        final resources = await _enabledResources();
        if (resources.isEmpty) return const <SearchResult>[];

        final normalized = query.trim();
        final batches = await Future.wait<List<SearchResult>?>(
          resources.map((resource) => _searchSource(resource, normalized)),
        );
        final successful = batches.whereType<List<SearchResult>>().toList();
        if (successful.isEmpty) {
          throw StateError('所有本地搜索源均失败');
        }
        return <SearchResult>[for (final batch in successful) ...batch];
      });

  Future<List<SearchResult>?> _searchSource(
    SearchResource resource,
    String query,
  ) async {
    try {
      return await _sourceService
          .search(resource, query)
          .timeout(const Duration(seconds: 20));
    } catch (error) {
      AppLogger.debug('单个本地搜索源失败：${error.runtimeType}');
      return null;
    }
  }

  @override
  Future<Result<List<SearchResult>>> getLocalDetail(String source, String id) =>
      _guard('获取播放源详情失败', () async {
        final resources = await _resources();
        final resource = resources
            .where((item) => item.key == source)
            .firstOrNull;
        if (resource == null) {
          throw StateError('未找到对应的源: $source');
        }
        return <SearchResult>[await _sourceService.fetchDetail(resource, id)];
      });

  Future<List<SearchResource>> _enabledResources() async => (await _resources())
      .where((resource) => !resource.disabled)
      .toList(growable: false);

  Future<List<SearchResource>> _resources() async {
    if (_isLocalMode) return _sourceService.getLocalSources();
    final cached = _cachedResources;
    if (cached != null) {
      if (_refreshingResources == null) {
        final refresh = _refreshResources(_cacheGeneration);
        _refreshingResources = refresh;
        unawaited(
          refresh.then<void>(
            (_) {},
            onError: (Object error, StackTrace stackTrace) {
              AppLogger.debug(
                '刷新搜索源缓存失败',
                error: error,
                stackTrace: stackTrace,
              );
            },
          ),
        );
      }
      return cached;
    }
    return _refreshingResources ??= _refreshResources(_cacheGeneration);
  }

  Future<List<SearchResource>> _refreshResources(int generation) async {
    try {
      final resources = await _apiService.getSearchResources();
      final immutable = List<SearchResource>.unmodifiable(resources);
      if (generation == _cacheGeneration) {
        _cachedResources = immutable;
      }
      return immutable;
    } finally {
      if (generation == _cacheGeneration) {
        _refreshingResources = null;
      }
    }
  }

  Future<Result<T>> _guard<T>(
    String message,
    Future<T> Function() action,
  ) async {
    try {
      return Success<T>(await action());
    } catch (error, stackTrace) {
      return FailureResult<T>(
        AppFailure(
          kind: error is TimeoutException
              ? FailureKind.timeout
              : FailureKind.network,
          message: message,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
