import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_release_asset.dart';

part 'app_version.freezed.dart';

@freezed
abstract class AppVersionInfo with _$AppVersionInfo {
  const factory AppVersionInfo({
    required String currentVersion,
    required String latestVersion,
    required String releaseNotes,
    required Uri releaseUri,
    AppReleaseAsset? androidAsset,
  }) = _AppVersionInfo;
}
