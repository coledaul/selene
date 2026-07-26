import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/services/douban_cache_service.dart';

void main() {
  test('豆瓣缓存定期清理可安全启动、重复调用和释放后重启', () {
    final service = DoubanCacheService();
    addTearDown(service.dispose);

    expect(service.startPeriodicCleanup, returnsNormally);
    expect(service.startPeriodicCleanup, returnsNormally);

    service.dispose();
    expect(service.startPeriodicCleanup, returnsNormally);
  });
}
