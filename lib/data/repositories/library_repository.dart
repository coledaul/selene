import '../../domain/models/auth_models.dart';
import '../../domain/models/favorite_item.dart';
import '../../domain/models/play_record.dart';
import '../../utils/result.dart';
import '../services/api_service.dart';
import '../services/library_local_service.dart';

abstract interface class LibraryRepository {
  void clearAllCache();
  Future<Result<List<PlayRecord>>> getPlayRecords({bool forceRefresh = false});
  Future<Result<void>> savePlayRecord(PlayRecord playRecord);
  Future<Result<void>> deletePlayRecord(String source, String id);
  Future<Result<void>> clearPlayRecords();
  Future<Result<List<FavoriteItem>>> getFavorites({bool forceRefresh = false});
  Future<Result<void>> addFavorite(
    String source,
    String id,
    Map<String, dynamic> favoriteData,
  );
  Future<Result<void>> removeFavorite(String source, String id);
  bool isFavorited(String source, String id);
  Future<Result<List<String>>> getSearchHistory({bool forceRefresh = false});
  Future<Result<void>> addSearchHistory(String query);
  Future<Result<void>> deleteSearchHistory(String query);
  Future<Result<void>> clearSearchHistory();
}

/// 播放历史、收藏和搜索历史的统一数据真相源。
final class DefaultLibraryRepository implements LibraryRepository {
  DefaultLibraryRepository({
    required ApiService apiService,
    required SessionState sessionState,
    LibraryLocalService? localService,
  }) : _apiService = apiService,
       _sessionState = sessionState,
       _localService = localService ?? const DefaultLibraryLocalService();

  static const _playRecordsKey = 'play_records';
  static const _favoritesKey = 'favorites';
  static const _searchHistoryKey = 'search_history';

  final ApiService _apiService;
  final SessionState _sessionState;
  final LibraryLocalService _localService;
  final Map<String, Object> _cache = <String, Object>{};
  int _cacheGeneration = 0;

  bool get _isLocalMode => _sessionState.status == AuthStatus.localMode;

  @override
  void clearAllCache() {
    _cacheGeneration++;
    _cache.clear();
  }

  @override
  Future<Result<List<PlayRecord>>> getPlayRecords({
    bool forceRefresh = false,
  }) async {
    if (_isLocalMode) {
      return _guard('获取播放记录失败', _localService.getPlayRecords);
    }
    final cached = _read<List<PlayRecord>>(_playRecordsKey);
    if (!forceRefresh && cached != null) return Success(cached);
    final generation = _cacheGeneration;
    return _guard('获取播放记录失败', () async {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/api/playrecords',
      );
      if (!response.success || response.data == null) {
        throw StateError(response.message ?? '服务端未返回播放记录');
      }
      final records = <PlayRecord>[];
      for (final entry in response.data!.entries) {
        try {
          records.add(PlayRecord.fromJson(entry.key, entry.value));
        } catch (_) {
          // 单条损坏记录不影响其余有效数据。
        }
      }
      records.sort((left, right) => right.saveTime.compareTo(left.saveTime));
      return _storeIfCurrent(_playRecordsKey, records, generation);
    });
  }

  @override
  Future<Result<void>> savePlayRecord(PlayRecord playRecord) async {
    if (_isLocalMode) {
      return _guard('保存播放记录失败', () async {
        await _localService.savePlayRecord(playRecord);
      });
    }
    return _serverWrite(
      '保存播放记录失败',
      () {
        return _apiService.savePlayRecord(playRecord);
      },
      () {
        final current = _read<List<PlayRecord>>(_playRecordsKey) ?? const [];
        final updated = <PlayRecord>[
          playRecord,
          ...current.where(
            (item) =>
                item.source != playRecord.source || item.id != playRecord.id,
          ),
        ]..sort((left, right) => right.saveTime.compareTo(left.saveTime));
        _store(_playRecordsKey, updated);
      },
    );
  }

  @override
  Future<Result<void>> deletePlayRecord(String source, String id) async {
    if (_isLocalMode) {
      return _guard('删除播放记录失败', () async {
        await _localService.deletePlayRecord(source, id);
      });
    }
    return _serverWrite(
      '删除播放记录失败',
      () => _apiService.deletePlayRecord(source, id),
      () => _replaceWhere<PlayRecord>(
        _playRecordsKey,
        (item) => item.source != source || item.id != id,
      ),
    );
  }

  @override
  Future<Result<void>> clearPlayRecords() async {
    if (_isLocalMode) {
      return _guard('清空播放记录失败', _localService.clearPlayRecords);
    }
    return _serverWrite(
      '清空播放记录失败',
      _apiService.clearPlayRecord,
      () => _cache.remove(_playRecordsKey),
    );
  }

  @override
  Future<Result<List<FavoriteItem>>> getFavorites({
    bool forceRefresh = false,
  }) async {
    if (_isLocalMode) {
      return _guard('获取收藏夹失败', _localService.getFavorites);
    }
    final cached = _read<List<FavoriteItem>>(_favoritesKey);
    if (!forceRefresh && cached != null) return Success(cached);
    final generation = _cacheGeneration;
    return _guard('获取收藏夹失败', () async {
      final response = await _apiService.getFavorites();
      if (!response.success || response.data == null) {
        throw StateError(response.message ?? '服务端未返回收藏夹');
      }
      return _storeIfCurrent(
        _favoritesKey,
        response.data!.where((item) => item.origin != 'live').toList(),
        generation,
      );
    });
  }

  @override
  Future<Result<void>> addFavorite(
    String source,
    String id,
    Map<String, dynamic> favoriteData,
  ) async {
    final favorite = _favoriteFrom(source, id, favoriteData);
    if (_isLocalMode) {
      return _guard('添加收藏失败', () async {
        await _localService.saveFavorite(favorite);
      });
    }
    return _serverWrite(
      '添加收藏失败',
      () => _apiService.favorite(source, id, favoriteData),
      () {
        final current = _read<List<FavoriteItem>>(_favoritesKey);
        if (current == null) return;
        _store(_favoritesKey, <FavoriteItem>[
          favorite,
          ...current.where((item) => item.source != source || item.id != id),
        ]);
      },
    );
  }

  @override
  Future<Result<void>> removeFavorite(String source, String id) async {
    if (_isLocalMode) {
      return _guard('取消收藏失败', () async {
        await _localService.deleteFavorite(source, id);
      });
    }
    return _serverWrite(
      '取消收藏失败',
      () => _apiService.unfavorite(source, id),
      () => _replaceWhere<FavoriteItem>(
        _favoritesKey,
        (item) => item.source != source || item.id != id,
      ),
    );
  }

  @override
  bool isFavorited(String source, String id) {
    if (_isLocalMode) return _localService.isFavorite(source, id);
    return _read<List<FavoriteItem>>(
          _favoritesKey,
        )?.any((item) => item.source == source && item.id == id) ??
        false;
  }

  @override
  Future<Result<List<String>>> getSearchHistory({
    bool forceRefresh = false,
  }) async {
    if (_isLocalMode) {
      return _guard('获取搜索历史失败', _localService.getSearchHistory);
    }
    final cached = _read<List<String>>(_searchHistoryKey);
    if (!forceRefresh && cached != null) return Success(cached);
    final generation = _cacheGeneration;
    return _guard('获取搜索历史失败', () async {
      final response = await _apiService.getSearchHistory();
      if (!response.success || response.data == null) {
        throw StateError(response.message ?? '服务端未返回搜索历史');
      }
      return _storeIfCurrent(_searchHistoryKey, response.data!, generation);
    });
  }

  @override
  Future<Result<void>> addSearchHistory(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return const FailureResult<void>(
        AppFailure(kind: FailureKind.validation, message: '搜索内容不能为空'),
      );
    }
    if (_isLocalMode) {
      return _guard('保存搜索历史失败', () async {
        await _localService.addSearchHistory(normalized);
      });
    }
    return _serverWrite(
      '保存搜索历史失败',
      () => _apiService.addSearchHistory(normalized),
      () {
        final current = _read<List<String>>(_searchHistoryKey) ?? const [];
        _store(_searchHistoryKey, <String>[
          normalized,
          ...current.where((item) => item != normalized),
        ]);
      },
    );
  }

  @override
  Future<Result<void>> deleteSearchHistory(String query) async {
    if (_isLocalMode) {
      return _guard('删除搜索历史失败', () async {
        await _localService.deleteSearchHistory(query);
      });
    }
    return _serverWrite(
      '删除搜索历史失败',
      () => _apiService.deleteSearchHistory(query),
      () => _replaceWhere<String>(_searchHistoryKey, (item) => item != query),
    );
  }

  @override
  Future<Result<void>> clearSearchHistory() async {
    if (_isLocalMode) {
      return _guard('清空搜索历史失败', _localService.clearSearchHistory);
    }
    return _serverWrite(
      '清空搜索历史失败',
      _apiService.clearSearchHistory,
      () => _cache.remove(_searchHistoryKey),
    );
  }

  FavoriteItem _favoriteFrom(
    String source,
    String id,
    Map<String, dynamic> data,
  ) => FavoriteItem(
    id: id,
    source: source,
    title: data['title']?.toString() ?? '',
    sourceName: data['source_name']?.toString() ?? '',
    year: data['year']?.toString() ?? '',
    cover: data['cover']?.toString() ?? '',
    totalEpisodes: data['total_episodes'] as int? ?? 0,
    saveTime:
        data['save_time'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    origin: '',
  );

  T? _read<T extends Object>(String key) => _cache[key] as T?;

  List<T> _store<T>(String key, Iterable<T> values) {
    final stored = List<T>.unmodifiable(values);
    _cache[key] = stored;
    return stored;
  }

  List<T> _storeIfCurrent<T>(String key, Iterable<T> values, int generation) {
    final stored = List<T>.unmodifiable(values);
    if (generation == _cacheGeneration) {
      _cache[key] = stored;
    }
    return stored;
  }

  void _replaceWhere<T>(String key, bool Function(T item) keep) {
    final current = _read<List<T>>(key);
    if (current != null) _store(key, current.where(keep));
  }

  Future<Result<void>> _serverWrite(
    String message,
    Future<ApiResponse<void>> Function() request,
    void Function() updateCache,
  ) {
    final generation = _cacheGeneration;
    return _guard(message, () async {
      final response = await request();
      if (!response.success) {
        throw StateError(response.message ?? message);
      }
      if (generation == _cacheGeneration) {
        updateCache();
      }
    });
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
          kind: FailureKind.network,
          message: message,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
