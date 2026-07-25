import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import '../../features/auth/application/auth_session_controller.dart';
import 'auth_retry_interceptor.dart';
import 'dio_authenticator.dart';
import 'session_cookie_store.dart';

abstract interface class MoonTvClient {
  Future<Response<dynamic>> request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? queryParameters,
    Object? data,
    Map<String, String>? headers,
    bool replayable = true,
    ResponseType responseType = ResponseType.json,
    CancelToken? cancelToken,
  });
}

class MoonTvApiClient implements MoonTvClient {
  MoonTvApiClient({
    required AuthSessionController sessionController,
    required SessionCookieStore cookieStore,
    Dio? dio,
  })  : _sessionController = sessionController,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                sendTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                contentType: Headers.jsonContentType,
                responseType: ResponseType.json,
              ),
            ) {
    if (!_dio.interceptors.any((interceptor) => interceptor is CookieManager)) {
      _dio.interceptors.add(cookieStore.createInterceptor());
    }
    _dio.interceptors.add(AuthRetryInterceptor(_dio, _sessionController));
  }

  final AuthSessionController _sessionController;
  final Dio _dio;

  @override
  Future<Response<dynamic>> request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? queryParameters,
    Object? data,
    Map<String, String>? headers,
    bool replayable = true,
    ResponseType responseType = ResponseType.json,
    CancelToken? cancelToken,
  }) {
    if (!_sessionController.isAuthenticated) {
      throw StateError('当前没有可用的服务器会话');
    }
    final serverUrl = _sessionController.profile.serverUrl;
    if (serverUrl.isEmpty) {
      throw StateError('服务器地址未配置，请先登录');
    }

    final normalizedEndpoint =
        endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return _dio.request<dynamic>(
      '$serverUrl$normalizedEndpoint',
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: Options(
        method: method,
        headers: headers,
        responseType: responseType,
        extra: <String, Object?>{
          AuthRequestOptions.replayable: replayable,
        },
      ),
    );
  }
}
