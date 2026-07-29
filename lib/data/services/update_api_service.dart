import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/models/app_version.dart';
import '../../utils/app_links.dart';
import '../../utils/result.dart';

abstract interface class UpdateApiService {
  Future<Result<AppVersionInfo?>> check();
  void dispose();
}

final class GitHubUpdateApiService implements UpdateApiService {
  GitHubUpdateApiService({
    Dio? dio,
    Dio Function()? dioFactory,
    Future<PackageInfo> Function()? packageInfo,
  }) : assert(dio == null || dioFactory == null),
       _dio = dio ?? (dioFactory ?? _createDio)(),
       _ownsDio = dio == null,
       _packageInfo = packageInfo ?? PackageInfo.fromPlatform;

  final Dio _dio;
  final bool _ownsDio;
  final Future<PackageInfo> Function() _packageInfo;
  bool _disposed = false;

  static Dio _createDio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: const <String, String>{'Accept': 'application/vnd.github+json'},
    ),
  );

  @override
  Future<Result<AppVersionInfo?>> check() async {
    final PackageInfo packageInfo;
    try {
      packageInfo = await _packageInfo();
    } catch (error, stackTrace) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.platform,
          message: '无法读取应用版本',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }

    try {
      final response = await _dio.getUri<Map<String, dynamic>>(
        AppLinks.latestReleaseApiUri,
      );
      final data = response.data;
      final rawTag = data?['tag_name'];
      if (rawTag is! String || rawTag.trim().isEmpty) {
        return const FailureResult(
          AppFailure(kind: FailureKind.parsing, message: '版本信息格式无效'),
        );
      }

      final tag = rawTag.trim();
      final latest = tag.startsWith('v') ? tag.substring(1) : tag;
      final rawReleaseUrl = data?['html_url'];
      final releaseUri = rawReleaseUrl is String
          ? Uri.tryParse(rawReleaseUrl)
          : null;
      if (latest.isEmpty ||
          releaseUri == null ||
          !AppLinks.isReleaseUri(releaseUri, tag: tag)) {
        return const FailureResult(
          AppFailure(kind: FailureKind.parsing, message: '版本信息格式无效'),
        );
      }

      if (!_isNewer(packageInfo.version, latest)) {
        return const Success<AppVersionInfo?>(null);
      }
      return Success<AppVersionInfo?>(
        AppVersionInfo(
          currentVersion: packageInfo.version,
          latestVersion: latest,
          releaseNotes: data?['body'] is String ? data!['body'] as String : '',
          releaseUri: releaseUri,
        ),
      );
    } on DioException catch (error, stackTrace) {
      if (error.response?.statusCode == 404) {
        return FailureResult(
          AppFailure(
            kind: FailureKind.notFound,
            message: '更新源暂无已发布版本',
            cause: error,
            stackTrace: stackTrace,
          ),
        );
      }
      return FailureResult(
        AppFailure(
          kind:
              error.type == DioExceptionType.connectionTimeout ||
                  error.type == DioExceptionType.receiveTimeout ||
                  error.type == DioExceptionType.sendTimeout
              ? FailureKind.timeout
              : FailureKind.network,
          message: '检查版本更新失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.parsing,
          message: '版本信息格式无效',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  bool _isNewer(String current, String latest) {
    final currentParts = _parseVersion(current);
    final latestParts = _parseVersion(latest);
    final length = currentParts.length > latestParts.length
        ? currentParts.length
        : latestParts.length;
    for (var index = 0; index < length; index++) {
      final currentPart = index < currentParts.length ? currentParts[index] : 0;
      final latestPart = index < latestParts.length ? latestParts[index] : 0;
      if (latestPart != currentPart) {
        return latestPart > currentPart;
      }
    }
    return false;
  }

  List<int> _parseVersion(String value) => value
      .split(RegExp(r'[.+-]'))
      .map((part) => int.tryParse(part) ?? 0)
      .toList(growable: false);

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (_ownsDio) {
      _dio.close(force: true);
    }
  }
}
