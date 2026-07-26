import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/services/moon_tv_api_service.dart';
import 'package:selene/data/services/search_stream_service.dart';

void main() {
  group('DefaultSearchStreamService', () {
    test('将 Dio 原始字节流适配为可直接进行 UTF-8 解码的流', () async {
      final client = _RecordingMoonTvClient(
        responseData: ResponseBody.fromBytes(
          utf8.encode('data: {"type":"start"}\n\n'),
          200,
        ),
      );
      final service = DefaultSearchStreamService(client);

      final connection = await service.open('龙珠');

      await expectLater(
        connection.bytes.transform(utf8.decoder).join(),
        completion('data: {"type":"start"}\n\n'),
      );
    });

    test('使用固定的 SSE 请求契约并传递取消令牌', () async {
      final client = _RecordingMoonTvClient(
        responseData: ResponseBody.fromBytes(const <int>[], 200),
      );
      final service = DefaultSearchStreamService(client);

      final connection = await service.open('测试关键词');

      expect(client.endpoint, '/api/search/ws');
      expect(client.method, 'GET');
      expect(client.queryParameters, <String, dynamic>{'q': '测试关键词'});
      expect(client.headers, <String, String>{
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
      });
      expect(client.responseType, ResponseType.stream);
      expect(client.cancelToken, isNotNull);
      expect(client.cancelToken!.isCancelled, isFalse);

      connection.cancel();

      expect(client.cancelToken!.isCancelled, isTrue);
    });

    test('非 ResponseBody 响应明确判定为协议错误', () async {
      final service = DefaultSearchStreamService(
        _RecordingMoonTvClient(responseData: <String, dynamic>{}),
      );

      await expectLater(
        service.open('测试关键词'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            '服务器未返回有效的 SSE 数据流',
          ),
        ),
      );
    });
  });
}

final class _RecordingMoonTvClient implements MoonTvClient {
  _RecordingMoonTvClient({required this.responseData});

  final Object? responseData;
  String? endpoint;
  String? method;
  Map<String, dynamic>? queryParameters;
  Map<String, String>? headers;
  ResponseType? responseType;
  CancelToken? cancelToken;

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
  }) async {
    this.endpoint = endpoint;
    this.method = method;
    this.queryParameters = queryParameters;
    this.headers = headers;
    this.responseType = responseType;
    this.cancelToken = cancelToken;
    return Response<dynamic>(
      requestOptions: RequestOptions(path: endpoint),
      statusCode: 200,
      data: responseData,
    );
  }

  @override
  void dispose() {}
}
