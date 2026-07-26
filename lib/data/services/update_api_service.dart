import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/models/app_version.dart';
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

  static final Uri _latestReleaseUri = Uri.parse(
    'https://api.github.com/repos/MoonTechLab/Selene/releases/latest',
  );
  static const String _releaseBaseUrl =
      'https://github.com/MoonTechLab/Selene/releases/tag';

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
    try {
      final packageInfo = await _packageInfo();
      final response = await _dio.getUri<Map<String, dynamic>>(
        _latestReleaseUri,
      );
      final data = response.data;
      final rawTag = data?['tag_name'];
      if (rawTag is! String || rawTag.trim().isEmpty) {
        return const FailureResult(
          AppFailure(kind: FailureKind.parsing, message: '版本信息格式无效'),
        );
      }

      final latest = rawTag.startsWith('v') ? rawTag.substring(1) : rawTag;
      if (!_isNewer(packageInfo.version, latest)) {
        return const Success<AppVersionInfo?>(null);
      }
      return Success<AppVersionInfo?>(
        AppVersionInfo(
          currentVersion: packageInfo.version,
          latestVersion: latest,
          releaseNotes: data?['body'] as String? ?? '',
          releaseUri: Uri.parse('$_releaseBaseUrl/v$latest'),
        ),
      );
    } on DioException catch (error, stackTrace) {
      return FailureResult(
        AppFailure(
          kind:
              error.type == DioExceptionType.connectionTimeout ||
                  error.type == DioExceptionType.receiveTimeout
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
          kind: FailureKind.platform,
          message: '无法读取应用版本',
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
