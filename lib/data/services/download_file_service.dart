import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/models/video_download_task.dart';

typedef DownloadRootDirectoryProvider = Future<Directory> Function();

class DownloadFilePaths {
  const DownloadFilePaths({
    required this.temporaryPath,
    required this.finalPath,
  });

  final String temporaryPath;
  final String finalPath;
}

class DownloadFileStore {
  DownloadFileStore({DownloadRootDirectoryProvider? rootDirectoryProvider})
    : _rootDirectoryProvider =
          rootDirectoryProvider ?? _defaultRootDirectoryProvider;

  final DownloadRootDirectoryProvider _rootDirectoryProvider;

  static Future<Directory> _defaultRootDirectoryProvider() async {
    final documents = await getApplicationDocumentsDirectory();
    return Directory('${documents.path}/Selene/Downloads');
  }

  Future<DownloadFilePaths> pathsFor(VideoDownloadTask task) async {
    final root = await _rootDirectoryProvider();
    await root.create(recursive: true);
    final title = sanitizeFileName(task.title, fallback: 'video');
    final episode = sanitizeFileName(task.episodeTitle, fallback: 'episode');
    final suffix = _stableHash(task.key);
    final fileName = '$title - $episode - $suffix.mkv';
    final finalPath = '${root.path}/$fileName';
    return DownloadFilePaths(
      temporaryPath: '$finalPath.part',
      finalPath: finalPath,
    );
  }

  Future<void> removeTemporary(VideoDownloadTask task) async {
    final paths = await pathsFor(task);
    final file = File(paths.temporaryPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> finalize(VideoDownloadTask task) async {
    final paths = await pathsFor(task);
    final temporaryFile = File(paths.temporaryPath);
    if (!await temporaryFile.exists() || await temporaryFile.length() == 0) {
      throw const FileSystemException('下载结果为空');
    }

    final finalFile = File(paths.finalPath);
    if (await finalFile.exists()) {
      await finalFile.delete();
    }
    await temporaryFile.rename(paths.finalPath);
    return paths.finalPath;
  }

  Future<bool> isValidCompletedFile(String? path) async {
    if (path == null || path.isEmpty) {
      return false;
    }
    final file = File(path);
    return await file.exists() && await file.length() > 0;
  }

  Future<void> deleteCompletedFile(String? path) async {
    if (path == null || path.isEmpty) {
      return;
    }
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static String sanitizeFileName(String value, {required String fallback}) {
    final sanitized = value
        .replaceAll(RegExp(r'[\\/:*?"<>|\u0000-\u001F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'[. ]+$'), '');
    if (sanitized.isEmpty) {
      return fallback;
    }
    return sanitized.length <= 64 ? sanitized : sanitized.substring(0, 64);
  }

  static String _stableHash(String value) {
    var hash = 0xcbf29ce484222325;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x100000001b3) & 0xffffffffffffffff;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
