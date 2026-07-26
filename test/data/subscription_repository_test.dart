import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/subscription_repository.dart';
import 'package:selene/data/services/subscription_api_service.dart';
import 'package:selene/data/services/subscription_local_service.dart';
import 'package:selene/domain/models/subscription.dart';
import 'package:selene/utils/result.dart';

void main() {
  test('订阅成功保存后失效本地搜索缓存代次', () async {
    final localService = _FakeSubscriptionLocalService();
    final invalidator = _TrackingSearchCacheInvalidator();
    final repository = DefaultSubscriptionRepository(
      apiService: _FakeSubscriptionApiService(),
      localService: localService,
      invalidateCaches: invalidator.clear,
    );
    addTearDown(repository.dispose);

    final result = await repository.save(_candidate);

    expect(result, isA<Success<void>>());
    expect(localService.saveCount, 1);
    expect(invalidator.clearCount, 1);
  });

  test('订阅保存失败时不提前失效当前可用缓存', () async {
    final localService = _FakeSubscriptionLocalService()..shouldFail = true;
    final invalidator = _TrackingSearchCacheInvalidator();
    final repository = DefaultSubscriptionRepository(
      apiService: _FakeSubscriptionApiService(),
      localService: localService,
      invalidateCaches: invalidator.clear,
    );
    addTearDown(repository.dispose);

    final result = await repository.save(_candidate);

    expect(result, isA<FailureResult<void>>());
    expect(invalidator.clearCount, 0);
  });
}

const _candidate = SubscriptionCandidate(
  url: 'https://example.com/subscription',
  searchSources: [],
  liveSources: [],
  replacesExistingData: true,
);

final class _TrackingSearchCacheInvalidator {
  int clearCount = 0;

  void clear() => clearCount++;
}

final class _FakeSubscriptionLocalService implements SubscriptionLocalService {
  int saveCount = 0;
  bool shouldFail = false;

  @override
  Future<String?> loadUrl() async => null;

  @override
  Future<void> save(
    SubscriptionCandidate candidate, {
    required bool clearOldData,
  }) async {
    saveCount++;
    if (shouldFail) throw StateError('保存失败');
  }
}

final class _FakeSubscriptionApiService implements SubscriptionApiService {
  @override
  Future<Result<SubscriptionPayload>> fetch(String url) async =>
      throw UnimplementedError();

  @override
  void dispose() {}
}
