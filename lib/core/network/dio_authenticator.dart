import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import '../../features/auth/application/auth_session_controller.dart';
import '../../features/auth/domain/auth_models.dart';
import 'session_cookie_store.dart';

class DioAuthenticator implements Authenticator {
  DioAuthenticator({
    Dio? dio,
    SessionCookieStore? cookieStore,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                sendTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                contentType: Headers.jsonContentType,
                responseType: ResponseType.json,
              ),
            ),
        _cookieStore = cookieStore ?? SessionCookieStore() {
    if (!_dio.interceptors.any((interceptor) => interceptor is CookieManager)) {
      _dio.interceptors.add(_cookieStore.createInterceptor());
    }
  }

  final Dio _dio;
  final SessionCookieStore _cookieStore;

  SessionCookieStore get cookieStore => _cookieStore;

  @override
  Future<AuthLoginResult> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    await _cookieStore.clear();

    try {
      await _dio.post<dynamic>(
        '$serverUrl/api/login',
        data: <String, String>{
          'username': username,
          'password': password,
        },
        options: Options(
          extra: const <String, Object?>{
            AuthRequestOptions.skipAuthenticationRetry: true,
          },
        ),
      );

      final identity = await _cookieStore.readIdentity(serverUrl);
      if (identity == null) {
        return const AuthLoginResult.failure(
          AuthLoginFailure.protocol,
          '服务器登录响应缺少认证 Cookie',
        );
      }
      return AuthLoginResult.success(role: identity.role);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        return const AuthLoginResult.invalidCredentials();
      }
      if (statusCode != null) {
        return AuthLoginResult.failure(
          AuthLoginFailure.protocol,
          _readServerMessage(error.response?.data) ?? '登录失败（HTTP $statusCode）',
        );
      }
      return const AuthLoginResult.failure(
        AuthLoginFailure.network,
        '无法连接服务器，请检查地址和网络',
      );
    } catch (_) {
      return const AuthLoginResult.failure(
        AuthLoginFailure.unknown,
        '登录过程中发生未知错误',
      );
    }
  }

  @override
  Future<void> clearSession() => _cookieStore.clear();

  String? _readServerMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'];
      return message is String && message.isNotEmpty ? message : null;
    }
    return null;
  }
}

abstract final class AuthRequestOptions {
  static const skipAuthenticationRetry = 'skipAuthenticationRetry';
  static const authenticationRetried = 'authenticationRetried';
  static const replayable = 'authenticationReplayable';
}
