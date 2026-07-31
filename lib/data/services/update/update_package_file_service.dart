import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../../domain/models/app_release_asset.dart';

abstract interface class UpdatePackageVerifier {
  Future<bool> verify(String filePath, AppReleaseAsset asset);
}

final class UpdatePackageFileService implements UpdatePackageVerifier {
  const UpdatePackageFileService();

  @override
  Future<bool> verify(String filePath, AppReleaseAsset asset) async {
    final file = File(filePath);
    if (!await file.exists() || await file.length() != asset.size) {
      return false;
    }
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString() == asset.sha256;
  }
}
