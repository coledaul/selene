import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

import '../../domain/models/download_export_outcome.dart';

abstract interface class DownloadExportService {
  Future<DownloadExportOutcome> export(String sourceFilePath);
}

typedef DownloadSaveLocationPicker =
    Future<String?> Function(String suggestedName);

final class PlatformDownloadExportService implements DownloadExportService {
  PlatformDownloadExportService({
    DownloadSaveLocationPicker? desktopSaveLocationPicker,
  }) : _desktopSaveLocationPicker =
           desktopSaveLocationPicker ?? _pickDesktopSaveLocation;

  static const _matroskaTypeGroup = XTypeGroup(
    label: 'Matroska 视频',
    extensions: <String>['mkv'],
  );

  final DownloadSaveLocationPicker _desktopSaveLocationPicker;

  @override
  Future<DownloadExportOutcome> export(String sourceFilePath) async {
    if (Platform.isAndroid || Platform.isIOS) {
      final savedPath = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          sourceFilePath: sourceFilePath,
          mimeTypesFilter: const <String>['video/x-matroska'],
        ),
      );
      return savedPath == null
          ? DownloadExportOutcome.cancelled
          : DownloadExportOutcome.exported;
    }

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      final sourceFile = File(sourceFilePath);
      final destinationPath = await _desktopSaveLocationPicker(
        _fileName(sourceFile),
      );
      if (destinationPath == null) {
        return DownloadExportOutcome.cancelled;
      }
      final destinationFile = File(destinationPath);
      final isSameFile = await destinationFile.exists()
          ? await FileSystemEntity.identical(
              sourceFile.path,
              destinationFile.path,
            )
          : false;
      if (!isSameFile) {
        await sourceFile.copy(destinationFile.path);
      }
      return DownloadExportOutcome.exported;
    }

    throw UnsupportedError('当前平台不支持下载文件导出');
  }

  static Future<String?> _pickDesktopSaveLocation(String suggestedName) async {
    final saveLocation = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: const <XTypeGroup>[_matroskaTypeGroup],
    );
    return saveLocation?.path;
  }

  static String _fileName(File file) {
    final segments = file.uri.pathSegments;
    if (segments.isEmpty || segments.last.isEmpty) {
      throw const FileSystemException('下载文件名无效');
    }
    return segments.last;
  }
}
