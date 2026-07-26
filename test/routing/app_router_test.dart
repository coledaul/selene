import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:selene/domain/models/auth_models.dart';
import 'package:selene/routing/app_router.dart';
import 'package:selene/routing/routes.dart';

void main() {
  group('authRedirect', () {
    test('初始化阶段只能停留在 loading', () {
      expect(authRedirect(AuthStatus.initializing, '/'), '/loading');
      expect(authRedirect(AuthStatus.initializing, '/loading'), isNull);
    });

    test('未登录和登录中统一进入登录页', () {
      expect(authRedirect(AuthStatus.unauthenticated, '/'), '/login');
      expect(authRedirect(AuthStatus.authenticating, '/loading'), '/login');
      expect(authRedirect(AuthStatus.unauthenticated, '/login'), isNull);
    });

    test('服务器会话和本地模式都离开认证页面进入首页', () {
      expect(authRedirect(AuthStatus.authenticated, '/login'), '/');
      expect(authRedirect(AuthStatus.localMode, '/loading'), '/');
      expect(authRedirect(AuthStatus.authenticated, '/'), isNull);
    });
  });

  test('会话根页面保持旧版无转场切换', () {
    final page = buildSessionRootPage(
      key: const ValueKey<String>('session-root'),
      child: const SizedBox.shrink(),
    );

    expect(page, isA<NoTransitionPage<void>>());
    expect(page.transitionDuration, Duration.zero);
    expect(page.reverseTransitionDuration, Duration.zero);
  });
}
