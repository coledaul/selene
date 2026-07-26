import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/app/session_cache_coordinator.dart';
import 'package:selene/data/repositories/auth_repository.dart';
import 'package:selene/data/repositories/cache_repository.dart';
import 'package:selene/data/repositories/library_repository.dart';
import 'package:selene/data/repositories/live_repository.dart';
import 'package:selene/data/repositories/search_repository.dart';
import 'package:selene/data/repositories/subscription_repository.dart';
import 'package:selene/domain/models/auth_models.dart';
import 'package:selene/utils/result.dart';

void main() {
  group('SessionCacheCoordinator', () {
    late _MutableAuthRepository auth;
    late _FakeLibraryRepository library;
    late _FakeLiveRepository live;
    late _FakeSearchRepository search;
    late _FakeCacheRepository cache;
    late _FakeSubscriptionRepository subscription;
    late SessionCacheCoordinator coordinator;

    setUp(() {
      auth = _MutableAuthRepository(
        status: AuthStatus.authenticated,
        profile: const AuthProfile(
          serverUrl: 'https://server-a.example',
          username: 'alice',
        ),
      );
      library = _FakeLibraryRepository();
      live = _FakeLiveRepository();
      search = _FakeSearchRepository();
      cache = _FakeCacheRepository();
      subscription = _FakeSubscriptionRepository();
      coordinator = SessionCacheCoordinator(
        authRepository: auth,
        libraryRepository: library,
        liveRepository: live,
        searchRepository: search,
        cacheRepository: cache,
        subscriptionRepository: subscription,
      )..start();
    });

    tearDown(() => coordinator.dispose());

    test('自动 401 失效统一清空全部会话级缓存', () async {
      auth.update(status: AuthStatus.unauthenticated);
      await _flushAsyncWork();

      expect(library.clearCount, 1);
      expect(live.clearCount, 1);
      expect(search.clearCount, 1);
      expect(cache.searchClearCount, 1);
      expect(cache.catalogClearCount, 0);
      expect(subscription.refreshCount, 0);
    });

    test('相同状态下切换账号或服务器也会清空旧身份缓存', () async {
      auth.update(
        status: AuthStatus.authenticated,
        profile: const AuthProfile(
          serverUrl: 'https://server-b.example',
          username: 'bob',
        ),
      );
      await _flushAsyncWork();

      expect(library.clearCount, 1);
      expect(live.clearCount, 1);
      expect(search.clearCount, 1);
      expect(cache.searchClearCount, 1);
      expect(cache.catalogClearCount, 0);
    });

    test('进入本地模式清空服务器缓存并只刷新一次订阅', () async {
      auth.update(
        status: AuthStatus.localMode,
        profile: const AuthProfile(isLocalMode: true),
      );
      await _flushAsyncWork();

      expect(library.clearCount, 1);
      expect(live.clearCount, 1);
      expect(search.clearCount, 1);
      expect(cache.searchClearCount, 1);
      expect(cache.catalogClearCount, 0);
      expect(subscription.refreshCount, 1);

      auth.notifyWithoutIdentityChange();
      await _flushAsyncWork();

      expect(library.clearCount, 1);
      expect(subscription.refreshCount, 1);
    });

    test('释放后会话变化不再访问缓存仓库', () async {
      coordinator.dispose();

      auth.update(status: AuthStatus.unauthenticated);
      await _flushAsyncWork();

      expect(library.clearCount, 0);
      expect(live.clearCount, 0);
      expect(search.clearCount, 0);
      expect(cache.searchClearCount, 0);
      expect(cache.catalogClearCount, 0);
    });
  });
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

final class _MutableAuthRepository extends ChangeNotifier
    implements AuthRepository {
  _MutableAuthRepository({
    required AuthStatus status,
    required AuthProfile profile,
  }) : _status = status,
       _profile = profile;

  AuthStatus _status;
  AuthProfile _profile;

  void update({required AuthStatus status, AuthProfile? profile}) {
    _status = status;
    _profile = profile ?? _profile;
    notifyListeners();
  }

  void notifyWithoutIdentityChange() => notifyListeners();

  @override
  AuthStatus get status => _status;

  @override
  AuthProfile get profile => _profile;

  @override
  String get role => 'user';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeLibraryRepository implements LibraryRepository {
  int clearCount = 0;

  @override
  void clearAllCache() => clearCount++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeLiveRepository implements LiveRepository {
  int clearCount = 0;

  @override
  void clearAllCache() => clearCount++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeSearchRepository implements SearchRepository {
  int clearCount = 0;

  @override
  void clearCache() => clearCount++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeCacheRepository implements CacheRepository {
  int searchClearCount = 0;
  int catalogClearCount = 0;

  @override
  void clearSearchCache() => searchClearCount++;

  @override
  Future<Result<void>> clearCatalogAndSearch() async {
    catalogClearCount++;
    return const Success<void>(null);
  }

  @override
  void dispose() {}
}

final class _FakeSubscriptionRepository implements SubscriptionRepository {
  int refreshCount = 0;

  @override
  Future<Result<void>> refresh() async {
    refreshCount++;
    return const Success<void>(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
