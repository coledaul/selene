import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/auth_models.dart';
import '../services/auth_api_service.dart';
import '../services/auth_profile_service.dart';
import '../services/credential_service.dart';

abstract interface class AuthRepository
    implements Listenable, AuthenticatedSession, SessionState {
  @override
  AuthStatus get status;
  String get role;
  String? get message;

  /// 仅用于登录表单恢复用户明确允许保存的密码，不得记录或二次持久化。
  String? get rememberedPassword;

  Future<void> initialize();

  Future<AuthLoginResult> login({
    required String serverUrl,
    required String username,
    required String password,
    required bool rememberLogin,
  });

  Future<void> enterLocalMode();
  Future<void> leaveLocalMode();
  Future<void> logout();
  void clearMessage();
  void dispose();
}

class DefaultAuthRepository extends ChangeNotifier implements AuthRepository {
  DefaultAuthRepository({
    required AuthProfileStore profileStore,
    required CredentialStore credentialStore,
    required AuthApiService authenticator,
  }) : _profileStore = profileStore,
       _credentialStore = credentialStore,
       _authenticator = authenticator;

  final AuthProfileStore _profileStore;
  final CredentialStore _credentialStore;
  final AuthApiService _authenticator;

  AuthStatus _status = AuthStatus.initializing;
  AuthProfile _profile = const AuthProfile();
  String _role = 'user';
  String? _message;
  String? _activePassword;
  Future<bool>? _reauthentication;
  Future<void>? _sessionExpiration;

  @override
  AuthStatus get status => _status;
  @override
  AuthProfile get profile => _profile;
  @override
  String get role => _role;
  @override
  String? get message => _message;
  @override
  String? get rememberedPassword =>
      _profile.rememberLogin ? _activePassword : null;
  @override
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  @override
  Future<void> initialize() async {
    _setState(status: AuthStatus.initializing, message: null);

    try {
      await _profileStore.clearLegacySecrets();
      _profile = await _profileStore.load();

      if (_profile.isLocalMode) {
        if (!_profile.rememberLogin) {
          await _credentialStore.deletePassword();
        }
        _setState(status: AuthStatus.localMode, message: null);
        return;
      }

      if (!_profile.canAutoLogin) {
        await _credentialStore.deletePassword();
        _setState(status: AuthStatus.unauthenticated, message: null);
        return;
      }

      final password = await _credentialStore.readPassword();
      if (password == null || password.isEmpty) {
        await _disableRememberLogin();
        _setState(status: AuthStatus.unauthenticated, message: null);
        return;
      }

      _activePassword = password;
      final result = await _authenticate(password);
      if (result.isSuccess) {
        _role = result.role;
        _setState(status: AuthStatus.authenticated, message: null);
        return;
      }

      if (result.invalidatesCredentials) {
        await _clearCredentials();
      }
      _setState(
        status: AuthStatus.unauthenticated,
        message: result.message ?? '自动登录失败，请重新登录',
      );
    } catch (_) {
      _activePassword = null;
      _setState(status: AuthStatus.unauthenticated, message: '登录信息初始化失败，请重新登录');
    }
  }

  @override
  Future<AuthLoginResult> login({
    required String serverUrl,
    required String username,
    required String password,
    required bool rememberLogin,
  }) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty || password.isEmpty) {
      return const AuthLoginResult.failure(
        AuthLoginFailure.invalidCredentials,
        '请输入用户名和密码',
      );
    }

    late final String normalizedUrl;
    try {
      normalizedUrl = AuthProfile.normalizeServerUrl(serverUrl);
    } on FormatException catch (error) {
      return AuthLoginResult.failure(
        AuthLoginFailure.invalidServer,
        error.message,
      );
    }

    final candidate = AuthProfile(
      serverUrl: normalizedUrl,
      username: normalizedUsername,
      rememberLogin: rememberLogin,
      isLocalMode: false,
    );

    final previousProfile = _profile;
    _profile = candidate;
    _setState(status: AuthStatus.authenticating, message: null);
    final result = await _authenticate(password);

    if (!result.isSuccess) {
      _profile = previousProfile;
      _activePassword = null;
      _setState(status: AuthStatus.unauthenticated, message: result.message);
      return result;
    }

    try {
      if (rememberLogin) {
        await _credentialStore.writePassword(password);
      } else {
        await _credentialStore.deletePassword();
      }
      await _profileStore.save(candidate);
    } catch (_) {
      await _rollbackFailedLogin(previousProfile);
      _activePassword = null;
      const storageFailure = AuthLoginResult.failure(
        AuthLoginFailure.secureStorage,
        '无法安全保存登录状态，请检查系统安全存储',
      );
      _setState(
        status: AuthStatus.unauthenticated,
        message: storageFailure.message,
      );
      return storageFailure;
    }

    _activePassword = password;
    _role = result.role;
    _setState(status: AuthStatus.authenticated, message: null);
    return result;
  }

  Future<void> _rollbackFailedLogin(AuthProfile previousProfile) async {
    try {
      await _authenticator.clearSession();
    } catch (_) {
      // 保持原始存储异常作为对用户的主错误。
    }
    try {
      await _credentialStore.deletePassword();
    } catch (_) {
      // 安全存储不可用时仍需要将会话收敛到未登录态。
    }

    _profile = previousProfile.copyWith(rememberLogin: false);
    try {
      await _profileStore.save(_profile);
    } catch (_) {
      // 下次启动会再次执行凭据一致性检查。
    }
  }

  @override
  Future<bool> reauthenticate() {
    final existing = _reauthentication;
    if (existing != null) {
      return existing;
    }

    final future = _performReauthentication();
    _reauthentication = future;
    return future.whenComplete(() {
      if (identical(_reauthentication, future)) {
        _reauthentication = null;
      }
    });
  }

  Future<bool> _performReauthentication() async {
    final password = _activePassword;
    if (password == null || password.isEmpty || _profile.serverUrl.isEmpty) {
      await _expireSession();
      return false;
    }

    final result = await _authenticate(password);
    if (result.isSuccess) {
      _role = result.role;
      if (_status != AuthStatus.authenticated) {
        _setState(status: AuthStatus.authenticated, message: null);
      }
      return true;
    }

    if (result.invalidatesCredentials) {
      await _expireSession(message: result.message);
    }
    return false;
  }

  @override
  Future<void> enterLocalMode() async {
    await _authenticator.clearSession();
    _activePassword = null;
    _role = 'user';
    _profile = _profile.copyWith(isLocalMode: true);
    await _profileStore.save(_profile);
    _setState(status: AuthStatus.localMode, message: null);
  }

  @override
  Future<void> leaveLocalMode() async {
    _profile = _profile.copyWith(isLocalMode: false);
    await _profileStore.save(_profile);
    _setState(status: AuthStatus.unauthenticated, message: null);
  }

  @override
  Future<void> logout() => invalidateSession(message: null);

  @override
  Future<void> invalidateSession({String? message = '登录已失效，请重新登录'}) {
    final existing = _sessionExpiration;
    if (existing != null) {
      return existing;
    }
    final future = _expireSession(message: message);
    _sessionExpiration = future;
    return future.whenComplete(() {
      if (identical(_sessionExpiration, future)) {
        _sessionExpiration = null;
      }
    });
  }

  Future<AuthLoginResult> _authenticate(String password) {
    return _authenticator.login(
      serverUrl: _profile.serverUrl,
      username: _profile.username,
      password: password,
    );
  }

  Future<void> _expireSession({String? message}) async {
    var effectiveMessage = message;
    try {
      await _authenticator.clearSession();
    } catch (_) {
      effectiveMessage ??= '已退出，但会话清理失败，请重启应用';
    }

    _activePassword = null;
    try {
      await _credentialStore.deletePassword();
    } catch (_) {
      effectiveMessage ??= '已退出，但安全存储清理失败';
    }

    final shouldPersistProfile = _profile.rememberLogin || _profile.isLocalMode;
    _profile = _profile.copyWith(rememberLogin: false, isLocalMode: false);
    if (shouldPersistProfile) {
      try {
        await _profileStore.save(_profile);
      } catch (_) {
        effectiveMessage ??= '已退出，但退出状态无法保存';
      }
    }

    _role = 'user';
    _setState(status: AuthStatus.unauthenticated, message: effectiveMessage);
  }

  Future<void> _clearCredentials() async {
    _activePassword = null;
    await _credentialStore.deletePassword();
    await _disableRememberLogin();
  }

  Future<void> _disableRememberLogin() async {
    if (!_profile.rememberLogin) {
      return;
    }
    _profile = _profile.copyWith(rememberLogin: false);
    await _profileStore.save(_profile);
  }

  @override
  void clearMessage() {
    if (_message == null) {
      return;
    }
    _message = null;
    notifyListeners();
  }

  void _setState({required AuthStatus status, required String? message}) {
    _status = status;
    _message = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _authenticator.dispose();
    super.dispose();
  }
}
