import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/services/update/update_package_file_service.dart';
import 'package:selene/domain/models/app_release_asset.dart';

void main() {
  test('同时校验文件大小和流式 SHA-256', () async {
    final directory = await Directory.systemTemp.createTemp(
      'selene_update_verify_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final bytes = utf8.encode('verified apk bytes');
    final file = File('${directory.path}/update.apk');
    await file.writeAsBytes(bytes, flush: true);
    final asset = AppReleaseAsset(
      fileName: 'update.apk',
      downloadUri: Uri.parse(
        'https://github.com/coledaul/selene/releases/download/v1/update.apk',
      ),
      size: bytes.length,
      sha256: sha256.convert(bytes).toString(),
      architecture: AndroidArchitecture.arm64,
    );

    const service = UpdatePackageFileService();

    expect(await service.verify(file.path, asset), isTrue);
    expect(
      await service.verify(
        file.path,
        AppReleaseAsset(
          fileName: asset.fileName,
          downloadUri: asset.downloadUri,
          size: asset.size + 1,
          sha256: asset.sha256,
          architecture: asset.architecture,
        ),
      ),
      isFalse,
    );
  });
}
