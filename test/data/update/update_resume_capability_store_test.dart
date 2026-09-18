import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/services/update/update_resume_capability_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    final previous = SharedPreferencesAsyncPlatform.instance;
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({});
  });

  test('跨实例读取实际能力，未确认和明确不支持保持区分', () async {
    final first = SharedPreferencesUpdateResumeCapabilityStore();
    expect(await first.read('pending'), isNull);
    await first.write('supported', true);
    await first.write('unsupported', false);
    final restored = SharedPreferencesUpdateResumeCapabilityStore();
    expect(await restored.read('supported'), isTrue);
    expect(await restored.read('unsupported'), isFalse);
    expect(await restored.read('pending'), isNull);
  });

  test('清理只删除对应任务的能力，不影响其他任务', () async {
    final store = SharedPreferencesUpdateResumeCapabilityStore();
    await store.write('previous', true);
    await store.write('current', false);
    await store.remove('previous');
    await store.remove('missing');
    expect(await store.read('previous'), isNull);
    expect(await store.read('current'), isFalse);
  });

  test('插件自动重试后的新连接不能使用上一次连接的能力记录', () async {
    final store = SharedPreferencesUpdateResumeCapabilityStore();
    await store.write('task', true, retriesRemaining: 2);
    expect(await store.read('task', retriesRemaining: 2), isTrue);
    expect(await store.read('task', retriesRemaining: 1), isNull);
    await store.write('task', false, retriesRemaining: 1);
    expect(await store.read('task', retriesRemaining: 1), isFalse);
  });

  test('损坏的记录不能被误认为支持续传', () async {
    final store = SharedPreferencesUpdateResumeCapabilityStore();
    for (final value in [
      'broken',
      '{}',
      '{"supported":"true","retriesRemaining":0}',
    ]) {
      await SharedPreferencesAsync().setString(
        'update_resume_capability_task',
        value,
      );
      expect(await store.read('task'), isNull);
    }
  });
}
