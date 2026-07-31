import 'app_release_asset.dart';

enum UpdateDownloadSource { automatic, direct, proxy }

enum UpdateTransferPhase {
  idle,
  queued,
  downloading,
  paused,
  verifying,
  readyToInstall,
  awaitingPermission,
  installerLaunched,
  failed,
  cancelled,
}

final class UpdateTransferState {
  const UpdateTransferState({
    this.phase = UpdateTransferPhase.idle,
    this.version,
    this.asset,
    this.taskId,
    this.requestedSource = UpdateDownloadSource.automatic,
    this.activeSource,
    this.progress = 0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
  });

  final UpdateTransferPhase phase;
  final String? version;
  final AppReleaseAsset? asset;
  final String? taskId;
  final UpdateDownloadSource requestedSource;
  final UpdateDownloadSource? activeSource;
  final double progress;
  final int downloadedBytes;
  final int totalBytes;
  final String? errorMessage;

  bool get isActive => switch (phase) {
    UpdateTransferPhase.queued ||
    UpdateTransferPhase.downloading ||
    UpdateTransferPhase.verifying ||
    UpdateTransferPhase.awaitingPermission => true,
    _ => false,
  };

  bool get canPause => phase == UpdateTransferPhase.downloading;
  bool get canResume => phase == UpdateTransferPhase.paused;
  bool get canCancel => switch (phase) {
    UpdateTransferPhase.queued ||
    UpdateTransferPhase.downloading ||
    UpdateTransferPhase.paused => true,
    _ => false,
  };

  UpdateTransferState copyWith({
    UpdateTransferPhase? phase,
    String? version,
    AppReleaseAsset? asset,
    String? taskId,
    UpdateDownloadSource? requestedSource,
    UpdateDownloadSource? activeSource,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    String? errorMessage,
    bool clearError = false,
  }) => UpdateTransferState(
    phase: phase ?? this.phase,
    version: version ?? this.version,
    asset: asset ?? this.asset,
    taskId: taskId ?? this.taskId,
    requestedSource: requestedSource ?? this.requestedSource,
    activeSource: activeSource ?? this.activeSource,
    progress: progress ?? this.progress,
    downloadedBytes: downloadedBytes ?? this.downloadedBytes,
    totalBytes: totalBytes ?? this.totalBytes,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}
