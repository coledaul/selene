import '../../domain/models/auth_models.dart';

abstract interface class AuthApiService {
  Future<AuthLoginResult> login({
    required String serverUrl,
    required String username,
    required String password,
  });

  Future<void> clearSession();

  void dispose();
}

abstract interface class AuthenticatedSession {
  bool get isAuthenticated;
  AuthProfile get profile;

  Future<bool> reauthenticate();

  Future<void> invalidateSession({String? message});
}
