import 'dart:convert';

import 'package:bs58check/bs58check.dart' as bs58;
import 'package:dio/dio.dart';

import '../../domain/models/live_source.dart';
import '../../domain/models/search_resource.dart';
import '../../utils/result.dart';

class SubscriptionPayload {
  const SubscriptionPayload({
    required this.searchSources,
    required this.liveSources,
  });

  final List<SearchResource> searchSources;
  final List<LiveSource> liveSources;
}

abstract interface class SubscriptionApiService {
  Future<Result<SubscriptionPayload>> fetch(String url);
  void dispose();
}

class DioSubscriptionApiService implements SubscriptionApiService {
  DioSubscriptionApiService({Dio? dio, Dio Function()? dioFactory})
    : assert(dio == null || dioFactory == null),
      _dio = dio ?? (dioFactory ?? _createDio)(),
      _ownsDio = dio == null;

  final Dio _dio;
  final bool _ownsDio;
  bool _disposed = false;

  static Dio _createDio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.plain,
    ),
  );

  @override
  Future<Result<SubscriptionPayload>> fetch(String url) async {
    try {
      final response = await _dio.get<String>(url);
      final content = response.data;
      if (content == null || content.isEmpty) {
        return const FailureResult(
          AppFailure(kind: FailureKind.protocol, message: '订阅内容格式无效'),
        );
      }
      return _parse(content);
    } on DioException catch (error, stackTrace) {
      final isTimeout =
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout;
      final statusCode = error.response?.statusCode;
      return FailureResult(
        AppFailure(
          kind: isTimeout ? FailureKind.timeout : FailureKind.network,
          message: isTimeout
              ? '订阅请求超时'
              : statusCode == null
              ? '无法获取订阅，请检查地址和网络'
              : '获取订阅内容失败（HTTP $statusCode）',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.parsing,
          message: '订阅内容格式无效',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Result<SubscriptionPayload> _parse(String content) {
    try {
      final decoded = bs58.base58.decode(content);
      final json = jsonDecode(utf8.decode(decoded));
      if (json is! Map<String, dynamic>) {
        throw const FormatException('订阅根节点不是对象');
      }

      final searchSources = <SearchResource>[];
      final apiSites = json['api_site'];
      if (apiSites is Map<String, dynamic>) {
        for (final entry in apiSites.entries) {
          final value = entry.value;
          if (value is! Map<String, dynamic>) {
            continue;
          }
          searchSources.add(
            SearchResource(
              key: value['key'] as String? ?? entry.key,
              name: value['name'] as String? ?? '',
              api: value['api'] as String? ?? '',
              detail: value['detail'] as String? ?? '',
              from: value['from'] as String? ?? '',
              disabled: false,
            ),
          );
        }
      }

      final liveSources = <LiveSource>[];
      final lives = json['lives'];
      if (lives is Map<String, dynamic>) {
        for (final entry in lives.entries) {
          final value = entry.value;
          if (value is! Map<String, dynamic>) {
            continue;
          }
          liveSources.add(
            LiveSource(
              key: value['key'] as String? ?? entry.key,
              name: value['name'] as String? ?? '',
              url: value['url'] as String? ?? '',
              ua: value['ua'] as String? ?? '',
              epg: value['epg'] as String? ?? '',
              from: value['from'] as String? ?? '',
              disabled: false,
            ),
          );
        }
      }

      if (searchSources.isEmpty && liveSources.isEmpty) {
        throw const FormatException('订阅不包含可用数据源');
      }
      return Success(
        SubscriptionPayload(
          searchSources: List.unmodifiable(searchSources),
          liveSources: List.unmodifiable(liveSources),
        ),
      );
    } catch (error, stackTrace) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.parsing,
          message: '订阅内容格式无效',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (_ownsDio) {
      _dio.close(force: true);
    }
  }
}
