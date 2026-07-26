import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/services/subscription_local_service.dart';
import 'package:selene/domain/models/search_resource.dart';
import 'package:selene/domain/models/subscription.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test('同一订阅刷新按完整快照替换搜索源和直播源', () async {
    final previousPlatform = SharedPreferencesAsyncPlatform.instance;
    addTearDown(() {
      SharedPreferencesAsyncPlatform.instance = previousPlatform;
    });
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData(<String, Object>{
          'local_mode_live_sources': '[{"key":"stale"}]',
        });
    final preferences = SharedPreferencesAsync();
    final service = SharedPreferencesSubscriptionLocalService(
      preferences: preferences,
    );

    await service.save(
      SubscriptionCandidate(
        url: 'https://example.com/subscription',
        searchSources: <SearchResource>[
          SearchResource(
            key: 'search',
            name: '搜索源',
            api: 'https://example.com/api',
            detail: '',
            from: 'test',
            disabled: false,
          ),
        ],
        liveSources: const [],
        replacesExistingData: false,
      ),
      clearOldData: false,
    );

    expect(
      await preferences.getString('local_mode_subscription_url'),
      'https://example.com/subscription',
    );
    expect(
      await preferences.getString('local_mode_search_sources'),
      contains('"key":"search"'),
    );
    expect(await preferences.getString('local_mode_live_sources'), '[]');
  });
}
