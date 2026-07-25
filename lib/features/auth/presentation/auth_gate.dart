import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../application/auth_session_controller.dart';
import '../domain/auth_models.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authenticated,
    required this.localMode,
    required this.unauthenticated,
    required this.loading,
  });

  final Widget authenticated;
  final Widget localMode;
  final Widget unauthenticated;
  final Widget loading;

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthSessionController>().status;
    switch (status) {
      case AuthStatus.authenticated:
        return _sessionNavigator('authenticated', authenticated);
      case AuthStatus.localMode:
        return _sessionNavigator('local-mode', localMode);
      case AuthStatus.unauthenticated:
      case AuthStatus.authenticating:
        return _sessionNavigator('unauthenticated', unauthenticated);
      case AuthStatus.initializing:
        return loading;
    }
  }

  Widget _sessionNavigator(String key, Widget root) {
    return Navigator(
      key: ValueKey<String>(key),
      onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => root),
    );
  }
}
