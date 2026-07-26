import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/services/moon_tv_api_service.dart';
import 'package:selene/data/services/api_service.dart';

void main() {
  group('ApiService response contract', () {
    test('204 或空响应对 void 写操作应判定成功', () async {
      final client = _FakeMoonTvClient(
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/searchhistory'),
          statusCode: 204,
          data: null,
        ),
      );
      final service = ApiService(client);

      final result = await service.post<void>('/api/searchhistory');

      expect(result.success, isTrue);
      expect(result.statusCode, 204);
    });

    test('JSON 响应只在业务门面执行一次类型转换', () async {
      final client = _FakeMoonTvClient(
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/data'),
          statusCode: 200,
          data: <String, dynamic>{'value': 7},
        ),
      );
      final service = ApiService(client);

      final result = await service.get<int>(
        '/api/data',
        fromJson: (data) => (data as Map<String, dynamic>)['value'] as int,
      );

      expect(result.success, isTrue);
      expect(result.data, 7);
    });

    test('HTTP 错误统一映射且不会操作页面导航', () async {
      final options = RequestOptions(path: '/api/data');
      final client = _FakeMoonTvClient(
        error: DioException.badResponse(
          statusCode: 403,
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 403,
            data: <String, dynamic>{'message': '禁止访问'},
          ),
        ),
      );
      final service = ApiService(client);

      final result = await service.get<void>('/api/data');

      expect(result.success, isFalse);
      expect(result.statusCode, 403);
      expect(result.message, '禁止访问');
    });

    test('上传文件不可读时仍返回统一错误结果', () async {
      final client = _FakeMoonTvClient(
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/upload'),
          statusCode: 200,
        ),
      );
      final service = ApiService(client);

      final result = await service.uploadFile<void>(
        '/api/upload',
        '/definitely-not-existing/selene-upload.bin',
      );

      expect(result.success, isFalse);
      expect(result.message, '无法读取待上传文件');
    });
  });
}

class _FakeMoonTvClient implements MoonTvClient {
  _FakeMoonTvClient({this.response, this.error});

  final Response<dynamic>? response;
  final Object? error;

  @override
  void dispose() {}

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
    if (error != null) {
      throw error!;
    }
    return response!;
  }
}
