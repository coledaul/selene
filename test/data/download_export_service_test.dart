import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/services/download_export_service.dart';
import 'package:selene/domain/models/download_export_outcome.dart';

void main() {
  test('桌面端把完成文件复制到新目标路径', () async {
    if (!_isDesktop) {
      return;
    }
    final directory = await Directory.systemTemp.createTemp(
      'selene-download-export-service-test-',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final source = File('${directory.path}/测试视频.mkv');
    final destination = File('${directory.path}/已导出.mkv');
    await source.writeAsBytes(<int>[0, 1, 2, 3], flush: true);
    String? suggestedName;
    final service = PlatformDownloadExportService(
      desktopSaveLocationPicker: (value) async {
        suggestedName = value;
        return destination.path;
      },
    );

    final outcome = await service.export(source.path);

    expect(outcome, DownloadExportOutcome.exported);
    expect(suggestedName, '测试视频.mkv');
    expect(await destination.readAsBytes(), <int>[0, 1, 2, 3]);
    expect(await source.exists(), isTrue);
  });

  test('桌面端取消保存位置时不复制文件', () async {
    if (!_isDesktop) {
      return;
    }
    final directory = await Directory.systemTemp.createTemp(
      'selene-download-export-cancel-test-',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final source = File('${directory.path}/测试视频.mkv');
    await source.writeAsBytes(<int>[0, 1, 2, 3], flush: true);
    final service = PlatformDownloadExportService(
      desktopSaveLocationPicker: (_) async => null,
    );

    final outcome = await service.export(source.path);

    expect(outcome, DownloadExportOutcome.cancelled);
    expect(await source.exists(), isTrue);
    expect(await directory.list().length, 1);
  });

  test('桌面端选择源文件本身时不会覆盖或删除原文件', () async {
    if (!_isDesktop) {
      return;
    }
    final directory = await Directory.systemTemp.createTemp(
      'selene-download-export-same-file-test-',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final source = File('${directory.path}/测试视频.mkv');
    await source.writeAsBytes(<int>[0, 1, 2, 3], flush: true);
    final service = PlatformDownloadExportService(
      desktopSaveLocationPicker: (_) async => source.path,
    );

    final outcome = await service.export(source.path);

    expect(outcome, DownloadExportOutcome.exported);
    expect(await source.readAsBytes(), <int>[0, 1, 2, 3]);
  });
}

bool get _isDesktop =>
    Platform.isMacOS || Platform.isWindows || Platform.isLinux;
