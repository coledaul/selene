import 'dart:convert';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/core/network/auth_retry_interceptor.dart';
import 'package:selene/core/network/dio_authenticator.dart';
import 'package:selene/core/network/moon_tv_api_client.dart';
import 'package:selene/core/network/session_cookie_store.dart';
import 'package:selene/features/auth/application/auth_session_controller.dart';
import 'package:selene/features/auth/domain/auth_models.dart';
import 'package:selene/features/auth/infrastructure/auth_profile_store.dart';
import 'package:selene/features/auth/infrastructure/credential_store.dart';

void main() {
  group('SessionCookieStore', () {
    test('使用标准 CookieJar 保存认证 Cookie 并集中解析角色', () async {
      final jar = CookieJar();
      final store = SessionCookieStore(cookieJar: jar);
      final uri = Uri.parse('https://example.com/api/login');
      final value = Uri.encodeComponent(jsonEncode(<String, Object>{
        'role': 'admin',
      }));
      await jar.saveFromResponse(uri, <Cookie>[Cookie('auth', value)]);

      final identity = await store.readIdentity('https://example.com');

      expect(identity, isNotNull);
      expect(identity!.role, 'admin');
      await store.clear();
      expect(await store.readIdentity('https://example.com'), isNull);
    });
  });

  group('DioAuthenticator', () {
    test('登录成功必须由 CookieManager 收到有效 auth Cookie', () async {
      final dio = Dio();
      dio.httpClientAdapter = _CallbackAdapter((options, count) {
        return ResponseBody.fromString(
          '{}',
          200,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>['application/json'],
            'set-cookie': <String>[
              'auth=${Uri.encodeComponent(jsonEncode(<String, Object>{
                    'role': 'admin'
                  }))}; Path=/; HttpOnly',
            ],
          },
        );
      });
      final cookieStore = SessionCookieStore();
      final authenticator = DioAuthenticator(
        dio: dio,
        cookieStore: cookieStore,
      );

      final result = await authenticator.login(
        serverUrl: 'https://example.com',
        username: 'alice',
        password: 'secret',
      );

      expect(result.isSuccess, isTrue);
      expect(result.role, 'admin');
    });

    test('返回 200 但缺少 auth Cookie 时判定协议错误', () async {
      final dio = Dio();
      dio.httpClientAdapter = _CallbackAdapter(
        (options, count) => ResponseBody.fromString('{}', 200),
      );
      final authenticator = DioAuthenticator(
        dio: dio,
        cookieStore: SessionCookieStore(),
      );

      final result = await authenticator.login(
        serverUrl: 'https://example.com',
        username: 'alice',
        password: 'secret',
      );

      expect(result.failure, AuthLoginFailure.protocol);
    });
  });

  group('AuthRetryInterceptor', () {
    test('401 后重认证并且原请求最多重试一次', () async {
      final adapter = _CallbackAdapter((options, count) {
        if (count == 1) {
          return ResponseBody.fromString('unauthorized', 401);
        }
        return ResponseBody.fromString(
          jsonEncode(<String, Object>{'ok': true}),
          200,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>['application/json'],
          },
        );
      });
      final authenticator = _MemoryAuthenticator();
      final controller = await _authenticatedController(authenticator);
      authenticator.loginCount = 0;
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(AuthRetryInterceptor(dio, controller));

      final response = await dio.get<Map<String, dynamic>>(
        'https://example.com/api/data',
      );

      expect(response.data, <String, dynamic>{'ok': true});
      expect(adapter.requestCount, 2);
      expect(authenticator.loginCount, 1);
      expect(controller.status, AuthStatus.authenticated);
    });

    test('重试后仍为 401 时停止，不产生无限循环', () async {
      final adapter = _CallbackAdapter(
        (options, count) => ResponseBody.fromString('unauthorized', 401),
      );
      final authenticator = _MemoryAuthenticator();
      final controller = await _authenticatedController(authenticator);
      authenticator.loginCount = 0;
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(AuthRetryInterceptor(dio, controller));

      await expectLater(
        dio.get<void>('https://example.com/api/data'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.requestCount, 2);
      expect(authenticator.loginCount, 1);
      expect(controller.status, AuthStatus.unauthenticated);
    });
  });

  group('MoonTvApiClient', () {
    test('退出后拒绝继续发送需要会话的请求', () async {
      final authenticator = _MemoryAuthenticator();
      final controller = await _authenticatedController(authenticator);
      await controller.logout();
      final dio = Dio()
        ..httpClientAdapter = _CallbackAdapter(
          (options, count) => ResponseBody.fromString('{}', 200),
        );
      final client = MoonTvApiClient(
        sessionController: controller,
        cookieStore: SessionCookieStore(),
        dio: dio,
      );

      expect(
        () => client.request('/api/data'),
        throwsA(isA<StateError>()),
      );
    });
  });
}

Future<AuthSessionController> _authenticatedController(
  _MemoryAuthenticator authenticator,
) async {
  final controller = AuthSessionController(
    profileStore: _MemoryProfileStore(),
    credentialStore: _MemoryCredentialStore(),
    authenticator: authenticator,
  );
  await controller.login(
    serverUrl: 'https://example.com',
    username: 'alice',
    password: 'secret',
    rememberLogin: false,
  );
  return controller;
}

class _CallbackAdapter implements HttpClientAdapter {
  _CallbackAdapter(this.callback);

  final ResponseBody Function(RequestOptions options, int count) callback;
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    return callback(options, requestCount);
  }

  @override
  void close({bool force = false}) {}
}

class _MemoryAuthenticator implements Authenticator {
  int loginCount = 0;

  @override
  Future<void> clearSession() async {}

  @override
  Future<AuthLoginResult> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    loginCount++;
    return const AuthLoginResult.success();
  }
}

class _MemoryProfileStore implements AuthProfileStore {
  AuthProfile profile = const AuthProfile();

  @override
  Future<void> clearLegacySecrets() async {}

  @override
  Future<AuthProfile> load() async => profile;

  @override
  Future<void> save(AuthProfile profile) async {
    this.profile = profile;
  }
}

class _MemoryCredentialStore implements CredentialStore {
  @override
  Future<void> deletePassword() async {}

  @override
  Future<String?> readPassword() async => null;

  @override
  Future<void> writePassword(String password) async {}
}
