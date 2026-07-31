import '../../../domain/models/app_release_asset.dart';
import '../../../domain/models/app_update_transfer.dart';
import '../../../utils/app_links.dart';

final class UpdateSourceCandidate {
  const UpdateSourceCandidate({required this.source, required this.uri});

  final UpdateDownloadSource source;
  final Uri uri;
}

final class UpdateSourceResolver {
  const UpdateSourceResolver();

  List<UpdateSourceCandidate> resolve(
    AppReleaseAsset asset,
    UpdateDownloadSource source,
  ) => switch (source) {
    UpdateDownloadSource.automatic => <UpdateSourceCandidate>[
      UpdateSourceCandidate(
        source: UpdateDownloadSource.proxy,
        uri: AppLinks.releaseAssetProxyUri(asset.downloadUri),
      ),
      UpdateSourceCandidate(
        source: UpdateDownloadSource.direct,
        uri: asset.downloadUri,
      ),
    ],
    UpdateDownloadSource.direct => <UpdateSourceCandidate>[
      UpdateSourceCandidate(
        source: UpdateDownloadSource.direct,
        uri: asset.downloadUri,
      ),
    ],
    UpdateDownloadSource.proxy => <UpdateSourceCandidate>[
      UpdateSourceCandidate(
        source: UpdateDownloadSource.proxy,
        uri: AppLinks.releaseAssetProxyUri(asset.downloadUri),
      ),
    ],
  };
}
