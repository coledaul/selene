import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/auth_repository.dart';
import 'package:selene/data/repositories/subscription_repository.dart';
import 'package:selene/data/services/auth_api_service.dart';
import 'package:selene/domain/models/auth_models.dart';
import 'package:selene/domain/models/subscription.dart';
import 'package:selene/data/services/auth_profile_service.dart';
import 'package:selene/data/services/credential_service.dart';
import 'package:selene/ui/auth/view_models/login_view_model.dart';
import 'package:selene/ui/auth/widgets/login_screen.dart';
import 'package:selene/utils/result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('手机和平板共用唯一服务器登录表单并预填连接资料', (tester) async {
    final fixture = await _Fixture.create(
      const AuthProfile(serverUrl: 'https://example.com', username: 'alice'),
    );

    for (final size in <Size>[const Size(390, 844), const Size(1024, 768)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_app(fixture));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('server-url-field')), findsOneWidget);
      expect(find.byKey(const Key('username-field')), findsOneWidget);
      expect(find.byKey(const Key('password-field')), findsOneWidget);
      expect(find.byKey(const Key('remember-login-checkbox')), findsOneWidget);
      expect(find.text('记住登录'), findsOneWidget);
      expect(find.text('在此设备安全保存登录凭据，下次自动登录'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('server-url-field')))
            .controller!
            .text,
        'https://example.com',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('username-field')))
            .controller!
            .text,
        'alice',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('password-field')))
            .controller!
            .text,
        isEmpty,
      );
    }
    await tester.binding.setSurfaceSize(null);
  });

  test('登录表单保持手机 420 和平板 480 的原有最大宽度', () {
    expect(LoginScreen.contentMaxWidth(isTablet: false), 420);
    expect(LoginScreen.contentMaxWidth(isTablet: true), 480);
  });

  testWidgets('勾选记住登录后通过会话控制器安全保存密码', (tester) async {
    final fixture = await _Fixture.create(const AuthProfile());
    await tester.pumpWidget(_app(fixture));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('server-url-field')),
      'https://example.com/',
    );
    await tester.enterText(find.byKey(const Key('username-field')), 'alice');
    await tester.enterText(find.byKey(const Key('password-field')), 'secret');
    await tester.tap(find.byKey(const Key('remember-login-checkbox')));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, '登录'));
    await tester.pumpAndSettle();

    expect(fixture.authenticator.loginCount, 1);
    expect(fixture.authenticator.lastServerUrl, 'https://example.com');
    expect(fixture.credentials.password, 'secret');
    expect(fixture.controller.profile.rememberLogin, isTrue);
  });

  testWidgets('HTTP 登录地址显示明文传输风险', (tester) async {
    final fixture = await _Fixture.create(const AuthProfile());
    await tester.pumpWidget(_app(fixture));
    await tester.enterText(
      find.byKey(const Key('server-url-field')),
      'http://192.168.1.2:3000',
    );
    await tester.pump();

    expect(find.text('HTTP 不会加密传输用户名和密码，仅建议在可信局域网中使用。'), findsOneWidget);
  });

  testWidgets('服务器会话失效后在登录页展示原因', (tester) async {
    final fixture = await _Fixture.create(
      const AuthProfile(serverUrl: 'https://example.com', username: 'alice'),
    );
    await fixture.controller.invalidateSession(message: '登录已失效，请重新登录');

    await tester.pumpWidget(_app(fixture));
    await tester.pumpAndSettle();

    expect(find.text('登录已失效，请重新登录'), findsOneWidget);
  });
}

Widget _app(_Fixture fixture) {
  return MaterialApp(
    home: LoginScreen(
      viewModelFactory: () => LoginViewModel(
        authRepository: fixture.controller,
        subscriptionRepository: fixture.subscriptions,
      ),
    ),
  );
}

class _Fixture {
  const _Fixture({
    required this.controller,
    required this.credentials,
    required this.authenticator,
    required this.subscriptions,
  });

  final AuthRepository controller;
  final _MemoryCredentialStore credentials;
  final _MemoryAuthenticator authenticator;
  final _MemorySubscriptionRepository subscriptions;

  static Future<_Fixture> create(AuthProfile profile) async {
    final credentials = _MemoryCredentialStore();
    final authenticator = _MemoryAuthenticator();
    final controller = DefaultAuthRepository(
      profileStore: _MemoryProfileStore(profile),
      credentialStore: credentials,
      authenticator: authenticator,
    );
    await controller.initialize();
    return _Fixture(
      controller: controller,
      credentials: credentials,
      authenticator: authenticator,
      subscriptions: _MemorySubscriptionRepository(),
    );
  }
}

class _MemorySubscriptionRepository implements SubscriptionRepository {
  @override
  Future<String> loadUrl() async => '';

  @override
  Future<Result<SubscriptionCandidate>> prepare(String url) async {
    return Success(
      SubscriptionCandidate(
        url: url,
        searchSources: const [],
        liveSources: const [],
        replacesExistingData: false,
      ),
    );
  }

  @override
  Future<Result<void>> refresh() async => const Success<void>(null);

  @override
  Future<Result<void>> save(SubscriptionCandidate candidate) async =>
      const Success<void>(null);

  @override
  void dispose() {}
}

class _MemoryProfileStore implements AuthProfileStore {
  _MemoryProfileStore(this.profile);

  AuthProfile profile;

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
  String? password;

  @override
  Future<void> deletePassword() async => password = null;

  @override
  Future<String?> readPassword() async => password;

  @override
  Future<void> writePassword(String password) async {
    this.password = password;
  }
}

class _MemoryAuthenticator implements AuthApiService {
  int loginCount = 0;
  String? lastServerUrl;

  @override
  Future<void> clearSession() async {}

  @override
  void dispose() {}

  @override
  Future<AuthLoginResult> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    loginCount++;
    lastServerUrl = serverUrl;
    return const AuthLoginResult.success();
  }
}
