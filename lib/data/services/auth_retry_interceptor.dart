import 'package:dio/dio.dart';

import 'auth_api_service.dart';
import 'dio_auth_api_service.dart';

class AuthRetryInterceptor extends Interceptor {
  AuthRetryInterceptor(this._dio, this._session);

  final Dio _dio;
  final AuthenticatedSession _session;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final shouldSkip =
        options.extra[AuthRequestOptions.skipAuthenticationRetry] == true;
    final wasRetried =
        options.extra[AuthRequestOptions.authenticationRetried] == true;

    if (!isUnauthorized || shouldSkip) {
      handler.next(err);
      return;
    }

    if (wasRetried) {
      await _session.invalidateSession();
      handler.next(err);
      return;
    }

    final reauthenticated = await _session.reauthenticate();
    final replayable =
        options.extra[AuthRequestOptions.replayable] as bool? ?? true;
    if (!reauthenticated || !replayable) {
      handler.next(err);
      return;
    }

    options.extra[AuthRequestOptions.authenticationRetried] = true;
    try {
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
