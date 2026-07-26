import 'dart:io';

import 'package:dio/dio.dart';

import 'package:selene/data/services/moon_tv_api_service.dart';
import 'package:selene/domain/models/epg_program.dart';
import 'package:selene/domain/models/favorite_item.dart';
import 'package:selene/domain/models/live_channel.dart';
import 'package:selene/domain/models/live_source.dart';
import 'package:selene/domain/models/play_record.dart';
import 'package:selene/domain/models/search_resource.dart';
import 'package:selene/domain/models/search_result.dart';
import 'package:selene/domain/models/search_suggestion.dart';

class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success(T? data, {int? statusCode}) {
    return ApiResponse<T>(success: true, data: data, statusCode: statusCode);
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse<T>(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }

  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
}

class ApiService {
  const ApiService(this._client);

  final MoonTvClient _client;

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) {
    return _execute<T>(
      () => _client.request(
        endpoint,
        queryParameters: queryParameters,
        headers: headers,
      ),
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) {
    return _execute<T>(
      () => _client.request(
        endpoint,
        method: 'POST',
        data: body,
        headers: headers,
      ),
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) {
    return _execute<T>(
      () => _client.request(
        endpoint,
        method: 'PUT',
        data: body,
        headers: headers,
      ),
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) {
    return _execute<T>(
      () => _client.request(
        endpoint,
        method: 'DELETE',
        queryParameters: queryParameters,
        headers: headers,
      ),
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> uploadFile<T>(
    String endpoint,
    String filePath, {
    Map<String, String>? fields,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    late final FormData formData;
    try {
      formData = FormData.fromMap(<String, Object?>{
        ...?fields,
        'file': await MultipartFile.fromFile(filePath),
      });
    } on FileSystemException {
      return ApiResponse<T>.error('无法读取待上传文件');
    }
    return _execute<T>(
      () => _client.request(
        endpoint,
        method: 'POST',
        data: formData,
        headers: headers,
        replayable: false,
      ),
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> _execute<T>(
    Future<Response<dynamic>> Function() request, {
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await request();
      final data = response.data;
      if (data == null || (data is String && data.trim().isEmpty)) {
        return ApiResponse<T>.success(null, statusCode: response.statusCode);
      }
      if (fromJson != null) {
        return ApiResponse<T>.success(
          fromJson(data),
          statusCode: response.statusCode,
        );
      }
      return ApiResponse<T>.success(data as T, statusCode: response.statusCode);
    } on DioException catch (error) {
      return ApiResponse<T>.error(
        _mapDioError(error),
        statusCode: error.response?.statusCode,
      );
    } on StateError catch (error) {
      return ApiResponse<T>.error(error.message);
    } catch (_) {
      return ApiResponse<T>.error('响应数据解析失败');
    }
  }

  String _mapDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final serverMessage = _readServerMessage(error.response?.data);
    if (serverMessage != null) {
      return serverMessage;
    }

    switch (statusCode) {
      case 400:
        return '请求参数错误';
      case 401:
        return '登录已失效，请重新登录';
      case 403:
        return '没有权限访问';
      case 404:
        return '请求的资源不存在';
      case 500:
        return '服务器内部错误';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '网络请求超时';
      case DioExceptionType.connectionError:
        return '无法连接服务器，请检查网络';
      case DioExceptionType.cancel:
        return '请求已取消';
      default:
        return statusCode == null ? '网络请求失败' : '网络请求失败（$statusCode）';
    }
  }

  String? _readServerMessage(Object? data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }
    final message = data['message'] ?? data['error'];
    return message is String && message.isNotEmpty ? message : null;
  }

  Future<ApiResponse<List<FavoriteItem>>> getFavorites() async {
    final response = await get<Map<String, dynamic>>(
      '/api/favorites',
      fromJson: (data) => data as Map<String, dynamic>,
    );
    if (!response.success || response.data == null) {
      return ApiResponse<List<FavoriteItem>>.error(
        response.message ?? '获取收藏夹失败',
        statusCode: response.statusCode,
      );
    }

    try {
      final favorites =
          response.data!.entries
              .map((entry) => FavoriteItem.fromJson(entry.key, entry.value))
              .toList()
            ..sort((a, b) => b.saveTime.compareTo(a.saveTime));
      return ApiResponse<List<FavoriteItem>>.success(
        favorites,
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse<List<FavoriteItem>>.error('收藏夹数据格式错误');
    }
  }

  Future<ApiResponse<List<String>>> getSearchHistory() {
    return get<List<String>>(
      '/api/searchhistory',
      fromJson: (data) => (data as List<dynamic>).cast<String>(),
    );
  }

  Future<ApiResponse<void>> addSearchHistory(String query) {
    return post<void>(
      '/api/searchhistory',
      body: <String, String>{'keyword': query},
    );
  }

  Future<ApiResponse<void>> clearSearchHistory() {
    return delete<void>('/api/searchhistory');
  }

  Future<ApiResponse<void>> deleteSearchHistory(String query) {
    return delete<void>(
      '/api/searchhistory',
      queryParameters: <String, String>{'keyword': query},
    );
  }

  Future<ApiResponse<void>> savePlayRecord(PlayRecord playRecord) {
    return post<void>(
      '/api/playrecords',
      body: <String, Object?>{
        'key': '${playRecord.source}+${playRecord.id}',
        'record': playRecord.toJson(),
      },
    );
  }

  Future<ApiResponse<void>> deletePlayRecord(String source, String id) {
    return delete<void>(
      '/api/playrecords',
      queryParameters: <String, String>{'key': '$source+$id'},
    );
  }

  Future<ApiResponse<void>> clearPlayRecord() {
    return delete<void>('/api/playrecords');
  }

  Future<ApiResponse<void>> favorite(
    String source,
    String id,
    Map<String, dynamic> favoriteData,
  ) {
    return post<void>(
      '/api/favorites',
      body: <String, Object?>{'key': '$source+$id', 'favorite': favoriteData},
    );
  }

  Future<ApiResponse<void>> unfavorite(String source, String id) {
    return delete<void>(
      '/api/favorites',
      queryParameters: <String, String>{'key': '$source+$id'},
    );
  }

  Future<bool> checkConnection() async {
    final response = await get<dynamic>('/api/health');
    return response.success;
  }

  Future<List<SearchResult>> fetchSourceDetail(String source, String id) async {
    final response = await get<SearchResult>(
      '/api/detail',
      queryParameters: <String, String>{'source': source, 'id': id},
      fromJson: (data) => SearchResult.fromJson(data as Map<String, dynamic>),
    );
    return response.data == null
        ? <SearchResult>[]
        : <SearchResult>[response.data!];
  }

  Future<List<SearchResult>> fetchSourcesData(String query) async {
    final response = await get<Map<String, dynamic>>(
      '/api/search',
      queryParameters: <String, String>{'q': query.trim()},
      fromJson: (data) => data as Map<String, dynamic>,
    );
    final results = response.data?['results'];
    if (results is! List<dynamic>) {
      return <SearchResult>[];
    }
    return results
        .map((item) => SearchResult.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<SearchResource>> getSearchResources() async {
    final response = await get<List<SearchResource>>(
      '/api/search/resources',
      fromJson: (data) => (data as List<dynamic>)
          .map((item) => SearchResource.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? <SearchResource>[];
  }

  Future<List<LiveSource>> getLiveSources() async {
    final response = await get<List<LiveSource>>(
      '/api/live/sources',
      fromJson: (data) =>
          ((data as Map<String, dynamic>)['data'] as List<dynamic>)
              .map((item) => LiveSource.fromJson(item as Map<String, dynamic>))
              .toList(),
    );
    return response.data ?? <LiveSource>[];
  }

  Future<List<LiveChannel>> getLiveChannels(String source) async {
    final response = await get<List<LiveChannel>>(
      '/api/live/channels',
      queryParameters: <String, String>{'source': source},
      fromJson: (data) =>
          ((data as Map<String, dynamic>)['data'] as List<dynamic>)
              .map((item) => LiveChannel.fromJson(item as Map<String, dynamic>))
              .toList(),
    );
    return response.data ?? <LiveChannel>[];
  }

  Future<EpgData?> getLiveEpg(String tvgId, String source) async {
    final response = await get<EpgData>(
      '/api/live/epg',
      queryParameters: <String, String>{'tvgId': tvgId, 'source': source},
      fromJson: (data) => EpgData.fromJson(
        (data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
      ),
    );
    return response.data;
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    final response = await get<List<SearchSuggestion>>(
      '/api/search/suggestions',
      queryParameters: <String, String>{'q': query.trim()},
      fromJson: (data) =>
          ((data as Map<String, dynamic>)['suggestions'] as List<dynamic>)
              .map(
                (item) =>
                    SearchSuggestion.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
    );
    return response.data
            ?.map((suggestion) => suggestion.text)
            .toList(growable: false) ??
        <String>[];
  }
}
