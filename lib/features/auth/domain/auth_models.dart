enum AuthStatus {
  initializing,
  unauthenticated,
  authenticating,
  authenticated,
  localMode,
}

class AuthProfile {
  const AuthProfile({
    this.serverUrl = '',
    this.username = '',
    this.rememberLogin = false,
    this.isLocalMode = false,
  });

  final String serverUrl;
  final String username;
  final bool rememberLogin;
  final bool isLocalMode;

  bool get canAutoLogin =>
      !isLocalMode &&
      rememberLogin &&
      serverUrl.isNotEmpty &&
      username.isNotEmpty;

  AuthProfile copyWith({
    String? serverUrl,
    String? username,
    bool? rememberLogin,
    bool? isLocalMode,
  }) {
    return AuthProfile(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      rememberLogin: rememberLogin ?? this.rememberLogin,
      isLocalMode: isLocalMode ?? this.isLocalMode,
    );
  }

  static String normalizeServerUrl(String value) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException('请输入有效的 HTTP(S) 服务器地址');
    }

    final normalizedPath =
        uri.path == '/' ? '' : uri.path.replaceFirst(RegExp(r'/+$'), '');
    return uri.replace(path: normalizedPath).toString();
  }
}

enum AuthLoginFailure {
  none,
  invalidCredentials,
  invalidServer,
  network,
  protocol,
  secureStorage,
  unknown,
}

class AuthLoginResult {
  const AuthLoginResult.success({this.role = 'user'})
      : failure = AuthLoginFailure.none,
        message = null;

  const AuthLoginResult.invalidCredentials({
    this.message = '用户名或密码错误',
  })  : failure = AuthLoginFailure.invalidCredentials,
        role = 'user';

  const AuthLoginResult.failure(this.failure, this.message) : role = 'user';

  final AuthLoginFailure failure;
  final String? message;
  final String role;

  bool get isSuccess => failure == AuthLoginFailure.none;
  bool get invalidatesCredentials =>
      failure == AuthLoginFailure.invalidCredentials ||
      failure == AuthLoginFailure.protocol;
}
