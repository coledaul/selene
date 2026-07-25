class VideoDownloadSettings {
  const VideoDownloadSettings({
    this.maxConcurrentDownloads = defaultMaxConcurrentDownloads,
  }) : assert(
          maxConcurrentDownloads >= minConcurrentDownloads &&
              maxConcurrentDownloads <= maxConcurrentDownloadsLimit,
        );

  static const int defaultMaxConcurrentDownloads = 3;
  static const int minConcurrentDownloads = 1;
  static const int maxConcurrentDownloadsLimit = 5;

  final int maxConcurrentDownloads;

  factory VideoDownloadSettings.normalized(int maxConcurrentDownloads) {
    return VideoDownloadSettings(
      maxConcurrentDownloads: maxConcurrentDownloads.clamp(
        minConcurrentDownloads,
        maxConcurrentDownloadsLimit,
      ),
    );
  }
}
