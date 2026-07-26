import 'package:go_router/go_router.dart';

import '../data/repositories/auth_repository.dart';
import '../domain/models/auth_models.dart';
import 'routes.dart';

class AppRouter {
  AppRouter(AuthRepository authRepository)
    : config = GoRouter(
        routes: $appRoutes,
        initialLocation: const AuthLoadingRoute().location,
        refreshListenable: authRepository,
        redirect: (context, state) =>
            authRedirect(authRepository.status, state.matchedLocation),
      );

  final GoRouter config;
}

String? authRedirect(AuthStatus status, String location) {
  return switch (status) {
    AuthStatus.initializing =>
      location == const AuthLoadingRoute().location
          ? null
          : const AuthLoadingRoute().location,
    AuthStatus.unauthenticated || AuthStatus.authenticating =>
      location == const LoginRoute().location
          ? null
          : const LoginRoute().location,
    AuthStatus.authenticated || AuthStatus.localMode =>
      location == const LoginRoute().location ||
              location == const AuthLoadingRoute().location
          ? const HomeRoute().location
          : null,
  };
}
