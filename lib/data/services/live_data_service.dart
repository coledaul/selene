import 'package:http/http.dart' as http;

import '../../domain/models/live_source.dart';
import 'local_mode_storage_service.dart';

abstract interface class LiveDataService {
  Future<List<LiveSource>> getLocalSources();
  Future<List<int>> download(String url, {Map<String, String>? headers});
  Future<Stream<List<int>>> openStream(
    String url, {
    Map<String, String>? headers,
  });
}

final class DefaultLiveDataService implements LiveDataService {
  const DefaultLiveDataService();

  @override
  Future<List<LiveSource>> getLocalSources() =>
      LocalModeStorageService.getLiveSources();

  @override
  Future<List<int>> download(String url, {Map<String, String>? headers}) async {
    final response = await http
        .get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('请求失败: ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  @override
  Future<Stream<List<int>>> openStream(
    String url, {
    Map<String, String>? headers,
  }) async {
    final request = http.Request('GET', Uri.parse(url));
    if (headers != null) request.headers.addAll(headers);
    final response = await request.send().timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('请求失败: ${response.statusCode}');
    }
    return response.stream;
  }
}
