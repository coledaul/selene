import '../../utils/result.dart';
import '../services/douban_cache_service.dart';
import '../services/local_search_cache_service.dart';

abstract interface class CacheRepository {
  void clearSearchCache();
  Future<Result<void>> clearCatalogAndSearch();
  void dispose();
}

final class DefaultCacheRepository implements CacheRepository {
  DefaultCacheRepository({
    required DoubanCacheService doubanCacheService,
    required LocalSearchCacheService localSearchCacheService,
  }) : _doubanCacheService = doubanCacheService,
       _localSearchCacheService = localSearchCacheService;

  final DoubanCacheService _doubanCacheService;
  final LocalSearchCacheService _localSearchCacheService;

  @override
  void clearSearchCache() => _localSearchCacheService.clearCache();

  @override
  Future<Result<void>> clearCatalogAndSearch() async {
    try {
      _localSearchCacheService.clearCache();
      await _doubanCacheService.clearAll();
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.storage,
          message: '清除内容缓存失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  void dispose() {
    _doubanCacheService.dispose();
    _localSearchCacheService.dispose();
  }
}
