import 'package:dio/dio.dart';

import '../../features/auth/application/auth_session_controller.dart';
import 'dio_authenticator.dart';

class AuthRetryInterceptor extends Interceptor {
  AuthRetryInterceptor(this._dio, this._sessionController);

  final Dio _dio;
  final AuthSessionController _sessionController;

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
      await _sessionController.invalidateSession();
      handler.next(err);
      return;
    }

    final reauthenticated = await _sessionController.reauthenticate();
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
