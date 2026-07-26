import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/services/local_search_cache_service.dart';

void main() {
  final cache = LocalSearchCacheService();

  setUp(cache.clearCache);
  tearDown(cache.clearCache);

  for (final status in CachedPageStatus.values) {
    test('清理后拒绝旧代次的 ${status.name} 缓存写入', () {
      final staleGeneration = cache.generation;
      cache.clearCache();

      cache.setCachedSearchPage('shared-key', '关键词', 1, status, const <String>[
        '旧订阅结果',
      ], generation: staleGeneration);

      expect(cache.getCachedSearchPage('shared-key', '关键词', 1), isNull);
    });
  }

  test('清理后开始的新代次请求可以正常写入并读取', () {
    final currentGeneration = cache.generation;

    cache.setCachedSearchPage(
      'shared-key',
      '关键词',
      1,
      CachedPageStatus.ok,
      const <String>['新订阅结果'],
      generation: currentGeneration,
      pageCount: 2,
    );

    final cached = cache.getCachedSearchPage('shared-key', '关键词', 1);
    expect(cached?.status, CachedPageStatus.ok);
    expect(cached?.data, const <String>['新订阅结果']);
    expect(cached?.pageCount, 2);
  });
}
