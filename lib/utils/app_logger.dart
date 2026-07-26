import 'dart:developer' as developer;

abstract final class AppLogger {
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'selene',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
