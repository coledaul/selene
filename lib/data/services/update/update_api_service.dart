import 'dart:ffi';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../domain/models/app_release_asset.dart';
import '../../../domain/models/app_version.dart';
import '../../../utils/app_links.dart';
import '../../../utils/result.dart';

abstract interface class UpdateApiService {
  Future<Result<AppVersionInfo?>> check();
  void dispose();
}

final class GitHubUpdateApiService implements UpdateApiService {
  GitHubUpdateApiService({
    Dio? dio,
    Dio Function()? dioFactory,
    Future<PackageInfo> Function()? packageInfo,
    bool Function()? isAndroid,
    AndroidArchitecture? Function()? androidArchitecture,
  }) : assert(dio == null || dioFactory == null),
       _dio = dio ?? (dioFactory ?? _createDio)(),
       _ownsDio = dio == null,
       _packageInfo = packageInfo ?? PackageInfo.fromPlatform,
       _isAndroid = isAndroid ?? _platformIsAndroid,
       _androidArchitecture = androidArchitecture ?? _currentArchitecture;

  final Dio _dio;
  final bool _ownsDio;
  final Future<PackageInfo> Function() _packageInfo;
  final bool Function() _isAndroid;
  final AndroidArchitecture? Function() _androidArchitecture;
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
      final architecture = _isAndroid() ? _androidArchitecture() : null;
      return Success<AppVersionInfo?>(
        AppVersionInfo(
          currentVersion: packageInfo.version,
          latestVersion: latest,
          releaseNotes: data?['body'] is String ? data!['body'] as String : '',
          releaseUri: releaseUri,
          androidAsset: architecture != null
              ? _parseAndroidAsset(
                  data?['assets'],
                  tag: tag,
                  version: latest,
                  architecture: architecture,
                )
              : null,
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

  AppReleaseAsset? _parseAndroidAsset(
    Object? rawAssets, {
    required String tag,
    required String version,
    required AndroidArchitecture architecture,
  }) {
    if (rawAssets is! List<Object?>) {
      return null;
    }
    final suffix = switch (architecture) {
      AndroidArchitecture.arm64 => 'armv8',
      AndroidArchitecture.arm32 => 'armv7a',
    };
    final expectedName = 'selene-$version-$suffix.apk';
    final matches = rawAssets
        .whereType<Map<String, Object?>>()
        .where((asset) => asset['name'] == expectedName)
        .toList(growable: false);
    if (matches.length != 1) {
      return null;
    }

    final asset = matches.single;
    final rawSize = asset['size'];
    final rawDigest = asset['digest'];
    final rawUrl = asset['browser_download_url'];
    final uri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
    if (asset['state'] != 'uploaded' ||
        asset['content_type'] != 'application/vnd.android.package-archive' ||
        rawSize is! int ||
        rawSize <= 0 ||
        rawDigest is! String ||
        uri == null ||
        !AppLinks.isReleaseAssetUri(uri, tag: tag) ||
        uri.pathSegments.last != expectedName) {
      return null;
    }
    final digest = RegExp(
      r'^sha256:([0-9a-fA-F]{64})$',
    ).firstMatch(rawDigest.trim());
    if (digest == null) {
      return null;
    }

    return AppReleaseAsset(
      fileName: expectedName,
      downloadUri: uri,
      size: rawSize,
      sha256: digest.group(1)!.toLowerCase(),
      architecture: architecture,
    );
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

  static bool _platformIsAndroid() => Platform.isAndroid;

  static AndroidArchitecture? _currentArchitecture() {
    final abi = Abi.current();
    if (abi == Abi.androidArm) return AndroidArchitecture.arm32;
    if (abi == Abi.androidArm64) return AndroidArchitecture.arm64;
    return null;
  }
}
