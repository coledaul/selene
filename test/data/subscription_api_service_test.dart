import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/services/subscription_api_service.dart';

void main() {
  group('DioSubscriptionApiService', () {
    test('超时保持旧版明确提示', () async {
      final dio = Dio()
        ..httpClientAdapter = _SubscriptionAdapter((options) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.receiveTimeout,
          );
        });
      addTearDown(() => dio.close(force: true));

      final result = await DioSubscriptionApiService(
        dio: dio,
      ).fetch('https://example.com/subscription');

      expect(result.failureOrNull?.message, '订阅请求超时');
    });

    test('HTTP 错误保持旧版提示', () async {
      final dio = Dio()
        ..httpClientAdapter = _SubscriptionAdapter(
          (_) => ResponseBody.fromString('not found', 404),
        );
      addTearDown(() => dio.close(force: true));

      final result = await DioSubscriptionApiService(
        dio: dio,
      ).fetch('https://example.com/subscription');

      expect(result.failureOrNull?.message, '获取订阅内容失败（HTTP 404）');
    });

    test('空响应按无效订阅内容处理', () async {
      final dio = Dio()
        ..httpClientAdapter = _SubscriptionAdapter(
          (_) => ResponseBody.fromString('', 200),
        );
      addTearDown(() => dio.close(force: true));

      final result = await DioSubscriptionApiService(
        dio: dio,
      ).fetch('https://example.com/subscription');

      expect(result.failureOrNull?.message, '订阅内容格式无效');
    });
  });
}

final class _SubscriptionAdapter implements HttpClientAdapter {
  _SubscriptionAdapter(this.callback);

  final ResponseBody Function(RequestOptions options) callback;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => callback(options);

  @override
  void close({bool force = false}) {}
}
