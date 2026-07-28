import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/auth_repository.dart';
import 'package:selene/data/services/auth_api_service.dart';
import 'package:selene/domain/models/auth_models.dart';
import 'package:selene/data/services/auth_profile_service.dart';
import 'package:selene/data/services/credential_service.dart';

void main() {
  group('AuthRepository', () {
    test('本地模式启动不会继续发起服务器自动登录', () async {
      final profileStore = _MemoryProfileStore(
        const AuthProfile(
          serverUrl: 'https://example.com',
          username: 'alice',
          rememberLogin: true,
          isLocalMode: true,
        ),
      );
      final credentials = _MemoryCredentialStore('secret');
      final authenticator = _FakeAuthenticator();
      final controller = _controller(profileStore, credentials, authenticator);

      await controller.initialize();

      expect(controller.status, AuthStatus.localMode);
      expect(authenticator.loginCount, 0);
    });

    test('未勾选记住登录时重启只恢复地址和用户名', () async {
      final profileStore = _MemoryProfileStore(
        const AuthProfile(
          serverUrl: 'https://example.com',
          username: 'alice',
          rememberLogin: false,
        ),
      );
      final credentials = _MemoryCredentialStore('should-not-be-read');
      final authenticator = _FakeAuthenticator();
      final controller = _controller(profileStore, credentials, authenticator);

      await controller.initialize();

      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.profile.serverUrl, 'https://example.com');
      expect(controller.profile.username, 'alice');
      expect(credentials.readCount, 0);
      expect(credentials.password, isNull);
      expect(authenticator.loginCount, 0);
    });

    test('自动登录网络失败时保留已记住密码', () async {
      final profileStore = _MemoryProfileStore(
        const AuthProfile(
          serverUrl: 'https://example.com',
          username: 'alice',
          rememberLogin: true,
        ),
      );
      final credentials = _MemoryCredentialStore('secret');
      final authenticator = _FakeAuthenticator()
        ..nextResult = const AuthLoginResult.failure(
          AuthLoginFailure.network,
          '无法连接服务器',
        );
      final controller = _controller(profileStore, credentials, authenticator);

      await controller.initialize();

      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.profile.rememberLogin, isTrue);
      expect(controller.rememberedPassword, 'secret');
      expect(credentials.password, 'secret');
    });

    test('自动登录凭据失效时不再恢复密码', () async {
      final profileStore = _MemoryProfileStore(
        const AuthProfile(
          serverUrl: 'https://example.com',
          username: 'alice',
          rememberLogin: true,
        ),
      );
      final credentials = _MemoryCredentialStore('wrong-secret');
      final authenticator = _FakeAuthenticator()
        ..nextResult = const AuthLoginResult.invalidCredentials();
      final controller = _controller(profileStore, credentials, authenticator);

      await controller.initialize();

      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.profile.rememberLogin, isFalse);
      expect(controller.rememberedPassword, isNull);
      expect(credentials.password, isNull);
    });

    test('保存连接资料失败时清理刚写入的密码和会话', () async {
      final profileStore = _MemoryProfileStore(
        const AuthProfile(),
        failSaves: true,
      );
      final credentials = _MemoryCredentialStore();
      final authenticator = _FakeAuthenticator();
      final controller = _controller(profileStore, credentials, authenticator);

      final result = await controller.login(
        serverUrl: 'https://example.com',
        username: 'alice',
        password: 'secret',
        rememberLogin: true,
      );

      expect(result.failure, AuthLoginFailure.secureStorage);
      expect(controller.status, AuthStatus.unauthenticated);
      expect(credentials.password, isNull);
      expect(authenticator.clearCount, 1);
    });

    test('登录成功后按用户选择安全保存或删除密码', () async {
      final profileStore = _MemoryProfileStore(const AuthProfile());
      final credentials = _MemoryCredentialStore();
      final authenticator = _FakeAuthenticator();
      final controller = _controller(profileStore, credentials, authenticator);

      final remembered = await controller.login(
        serverUrl: 'https://example.com/',
        username: 'alice',
        password: 'secret',
        rememberLogin: true,
      );

      expect(remembered.isSuccess, isTrue);
      expect(controller.status, AuthStatus.authenticated);
      expect(controller.profile.serverUrl, 'https://example.com');
      expect(credentials.password, 'secret');
      expect(controller.rememberedPassword, 'secret');

      final notRemembered = await controller.login(
        serverUrl: 'https://example.com',
        username: 'alice',
        password: 'new-secret',
        rememberLogin: false,
      );

      expect(notRemembered.isSuccess, isTrue);
      expect(credentials.password, isNull);
      expect(controller.profile.rememberLogin, isFalse);
      expect(controller.rememberedPassword, isNull);
    });

    test('并发 401 只执行一次重认证并共享结果', () async {
      final profileStore = _MemoryProfileStore(const AuthProfile());
      final credentials = _MemoryCredentialStore();
      final authenticator = _FakeAuthenticator();
      final controller = _controller(profileStore, credentials, authenticator);
      await controller.login(
        serverUrl: 'https://example.com',
        username: 'alice',
        password: 'secret',
        rememberLogin: false,
      );
      authenticator.loginCount = 0;
      authenticator.delayLogin = true;

      final attempts = List<Future<bool>>.generate(
        3,
        (_) => controller.reauthenticate(),
      );
      await Future<void>.delayed(Duration.zero);
      expect(authenticator.loginCount, 1);

      authenticator.completePending();
      expect(await Future.wait(attempts), everyElement(isTrue));
      expect(authenticator.loginCount, 1);
    });

    test('重认证凭据失效后只清会话和密码并保留连接资料', () async {
      final profileStore = _MemoryProfileStore(const AuthProfile());
      final credentials = _MemoryCredentialStore();
      final authenticator = _FakeAuthenticator();
      final controller = _controller(profileStore, credentials, authenticator);
      await controller.login(
        serverUrl: 'https://example.com',
        username: 'alice',
        password: 'secret',
        rememberLogin: true,
      );
      authenticator.nextResult = const AuthLoginResult.invalidCredentials();

      expect(await controller.reauthenticate(), isFalse);
      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.profile.serverUrl, 'https://example.com');
      expect(controller.profile.username, 'alice');
      expect(controller.profile.rememberLogin, isFalse);
      expect(credentials.password, isNull);
      expect(authenticator.clearCount, 1);
    });

    test('手动退出清理敏感状态但保留地址和用户名', () async {
      final profileStore = _MemoryProfileStore(const AuthProfile());
      final credentials = _MemoryCredentialStore();
      final authenticator = _FakeAuthenticator();
      final controller = _controller(profileStore, credentials, authenticator);
      await controller.login(
        serverUrl: 'https://example.com',
        username: 'alice',
        password: 'secret',
        rememberLogin: true,
      );

      await controller.logout();

      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.profile.serverUrl, 'https://example.com');
      expect(controller.profile.username, 'alice');
      expect(controller.profile.rememberLogin, isFalse);
      expect(credentials.password, isNull);
      expect(authenticator.clearCount, 1);
    });

    test('安全存储清理失败也会终止当前内存会话', () async {
      final profileStore = _MemoryProfileStore(const AuthProfile());
      final credentials = _MemoryCredentialStore();
      final authenticator = _FakeAuthenticator();
      final controller = _controller(profileStore, credentials, authenticator);
      await controller.login(
        serverUrl: 'https://example.com',
        username: 'alice',
        password: 'secret',
        rememberLogin: true,
      );
      credentials.failDeletes = true;

      await controller.logout();

      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.profile.rememberLogin, isFalse);
      expect(controller.message, isNotNull);
    });

    test('本地模式手动退出后不会在重启时自动进入', () async {
      final profileStore = _MemoryProfileStore(
        const AuthProfile(isLocalMode: true),
      );
      final credentials = _MemoryCredentialStore();
      final authenticator = _FakeAuthenticator();
      final controller = _controller(profileStore, credentials, authenticator);

      await controller.initialize();
      await controller.logout();

      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.profile.isLocalMode, isFalse);
      expect(profileStore.profile.isLocalMode, isFalse);
    });

    test('销毁 Repository 时同步释放鉴权 HTTP Service', () {
      final authenticator = _FakeAuthenticator();
      final controller = _controller(
        _MemoryProfileStore(const AuthProfile()),
        _MemoryCredentialStore(),
        authenticator,
      );

      controller.dispose();

      expect(authenticator.disposeCount, 1);
    });
  });
}

AuthRepository _controller(
  AuthProfileStore profileStore,
  CredentialStore credentialStore,
  AuthApiService authenticator,
) {
  return DefaultAuthRepository(
    profileStore: profileStore,
    credentialStore: credentialStore,
    authenticator: authenticator,
  );
}

class _MemoryProfileStore implements AuthProfileStore {
  _MemoryProfileStore(this.profile, {this.failSaves = false});

  AuthProfile profile;
  final bool failSaves;
  int clearLegacySecretsCount = 0;

  @override
  Future<void> clearLegacySecrets() async {
    clearLegacySecretsCount++;
  }

  @override
  Future<AuthProfile> load() async => profile;

  @override
  Future<void> save(AuthProfile profile) async {
    if (failSaves) {
      throw StateError('保存失败');
    }
    this.profile = profile;
  }
}

class _MemoryCredentialStore implements CredentialStore {
  _MemoryCredentialStore([this.password]);

  String? password;
  bool failDeletes = false;
  int readCount = 0;

  @override
  Future<void> deletePassword() async {
    if (failDeletes) {
      throw StateError('删除失败');
    }
    password = null;
  }

  @override
  Future<String?> readPassword() async {
    readCount++;
    return password;
  }

  @override
  Future<void> writePassword(String password) async {
    this.password = password;
  }
}

class _FakeAuthenticator implements AuthApiService {
  bool delayLogin = false;
  AuthLoginResult nextResult = const AuthLoginResult.success(role: 'admin');
  int loginCount = 0;
  int clearCount = 0;
  int disposeCount = 0;
  Completer<AuthLoginResult>? _pending;

  @override
  Future<void> clearSession() async {
    clearCount++;
  }

  @override
  void dispose() {
    disposeCount++;
  }

  @override
  Future<AuthLoginResult> login({
    required String serverUrl,
    required String username,
    required String password,
  }) {
    loginCount++;
    if (!delayLogin) {
      return Future<AuthLoginResult>.value(nextResult);
    }
    _pending = Completer<AuthLoginResult>();
    return _pending!.future;
  }

  void completePending() {
    _pending?.complete(nextResult);
  }
}
