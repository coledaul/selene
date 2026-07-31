enum AndroidArchitecture { arm64, arm32 }

final class AppReleaseAsset {
  const AppReleaseAsset({
    required this.fileName,
    required this.downloadUri,
    required this.size,
    required this.sha256,
    required this.architecture,
  });

  final String fileName;
  final Uri downloadUri;
  final int size;
  final String sha256;
  final AndroidArchitecture architecture;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppReleaseAsset &&
          other.fileName == fileName &&
          other.downloadUri == downloadUri &&
          other.size == size &&
          other.sha256 == sha256 &&
          other.architecture == architecture;

  @override
  int get hashCode =>
      Object.hash(fileName, downloadUri, size, sha256, architecture);
}
