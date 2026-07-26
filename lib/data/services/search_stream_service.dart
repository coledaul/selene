import 'package:dio/dio.dart';

import 'moon_tv_api_service.dart';

abstract interface class SearchStreamConnection {
  Stream<List<int>> get bytes;
  void cancel();
}

abstract interface class SearchStreamService {
  Future<SearchStreamConnection> open(String query);
}

final class DefaultSearchStreamService implements SearchStreamService {
  const DefaultSearchStreamService(this._client);

  final MoonTvClient _client;

  @override
  Future<SearchStreamConnection> open(String query) async {
    final cancelToken = CancelToken();
    final response = await _client.request(
      '/api/search/ws',
      queryParameters: <String, dynamic>{'q': query},
      headers: const <String, String>{
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
      },
      responseType: ResponseType.stream,
      cancelToken: cancelToken,
    );
    final body = response.data;
    if (body is! ResponseBody) {
      throw const FormatException('服务器未返回有效的 SSE 数据流');
    }
    return _DioSearchStreamConnection(
      body.stream.cast<List<int>>(),
      cancelToken,
    );
  }
}

final class _DioSearchStreamConnection implements SearchStreamConnection {
  const _DioSearchStreamConnection(this.bytes, this._cancelToken);

  @override
  final Stream<List<int>> bytes;
  final CancelToken _cancelToken;

  @override
  void cancel() => _cancelToken.cancel('用户取消搜索');
}
