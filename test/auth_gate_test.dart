import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:selene/features/auth/application/auth_session_controller.dart';
import 'package:selene/features/auth/domain/auth_models.dart';
import 'package:selene/features/auth/infrastructure/auth_profile_store.dart';
import 'package:selene/features/auth/infrastructure/credential_store.dart';
import 'package:selene/features/auth/presentation/auth_gate.dart';

void main() {
  testWidgets('会话失效会销毁已登录页面栈并显示登录页', (tester) async {
    final controller = AuthSessionController(
      profileStore: _ProfileStore(),
      credentialStore: _CredentialStore(),
      authenticator: _Authenticator(),
    );
    await controller.login(
      serverUrl: 'https://example.com',
      username: 'alice',
      password: 'secret',
      rememberLogin: false,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthSessionController>.value(
        value: controller,
        child: MaterialApp(
          home: AuthGate(
            authenticated: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: Text('详情页')),
                    ),
                  ),
                  child: const Text('打开详情'),
                ),
              ),
            ),
            localMode: const SizedBox.shrink(),
            unauthenticated: const Scaffold(body: Text('登录页')),
            loading: const Scaffold(body: Text('初始化')),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开详情'));
    await tester.pumpAndSettle();
    expect(find.text('详情页'), findsOneWidget);

    await controller.invalidateSession();
    await tester.pumpAndSettle();

    expect(find.text('详情页'), findsNothing);
    expect(find.text('登录页'), findsOneWidget);
  });
}

class _ProfileStore implements AuthProfileStore {
  AuthProfile profile = const AuthProfile();

  @override
  Future<void> clearLegacySecrets() async {}

  @override
  Future<AuthProfile> load() async => profile;

  @override
  Future<void> save(AuthProfile profile) async => this.profile = profile;
}

class _CredentialStore implements CredentialStore {
  @override
  Future<void> deletePassword() async {}

  @override
  Future<String?> readPassword() async => null;

  @override
  Future<void> writePassword(String password) async {}
}

class _Authenticator implements Authenticator {
  @override
  Future<void> clearSession() async {}

  @override
  Future<AuthLoginResult> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    return const AuthLoginResult.success();
  }
}
