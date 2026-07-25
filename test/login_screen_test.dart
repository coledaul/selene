import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:selene/features/auth/application/auth_session_controller.dart';
import 'package:selene/features/auth/domain/auth_models.dart';
import 'package:selene/features/auth/infrastructure/auth_profile_store.dart';
import 'package:selene/features/auth/infrastructure/credential_store.dart';
import 'package:selene/screens/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('手机和平板共用唯一服务器登录表单并预填连接资料', (tester) async {
    final fixture = await _Fixture.create(
      const AuthProfile(
        serverUrl: 'https://example.com',
        username: 'alice',
      ),
    );

    for (final size in <Size>[const Size(390, 844), const Size(1024, 768)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_app(fixture.controller));
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

  testWidgets('勾选记住登录后通过会话控制器安全保存密码', (tester) async {
    final fixture = await _Fixture.create(const AuthProfile());
    await tester.pumpWidget(_app(fixture.controller));
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
    await tester.pumpWidget(_app(fixture.controller));
    await tester.enterText(
      find.byKey(const Key('server-url-field')),
      'http://192.168.1.2:3000',
    );
    await tester.pump();

    expect(
      find.text('HTTP 不会加密传输用户名和密码，仅建议在可信局域网中使用。'),
      findsOneWidget,
    );
  });

  testWidgets('服务器会话失效后在登录页展示原因', (tester) async {
    final fixture = await _Fixture.create(
      const AuthProfile(
        serverUrl: 'https://example.com',
        username: 'alice',
      ),
    );
    await fixture.controller.invalidateSession(message: '登录已失效，请重新登录');

    await tester.pumpWidget(_app(fixture.controller));
    await tester.pumpAndSettle();

    expect(find.text('登录已失效，请重新登录'), findsOneWidget);
  });
}

Widget _app(AuthSessionController controller) {
  return ChangeNotifierProvider<AuthSessionController>.value(
    value: controller,
    child: const MaterialApp(home: LoginScreen()),
  );
}

class _Fixture {
  const _Fixture({
    required this.controller,
    required this.credentials,
    required this.authenticator,
  });

  final AuthSessionController controller;
  final _MemoryCredentialStore credentials;
  final _MemoryAuthenticator authenticator;

  static Future<_Fixture> create(AuthProfile profile) async {
    final credentials = _MemoryCredentialStore();
    final authenticator = _MemoryAuthenticator();
    final controller = AuthSessionController(
      profileStore: _MemoryProfileStore(profile),
      credentialStore: credentials,
      authenticator: authenticator,
    );
    await controller.initialize();
    return _Fixture(
      controller: controller,
      credentials: credentials,
      authenticator: authenticator,
    );
  }
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

class _MemoryAuthenticator implements Authenticator {
  int loginCount = 0;
  String? lastServerUrl;

  @override
  Future<void> clearSession() async {}

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
