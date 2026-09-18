import 'package:background_downloader/background_downloader.dart';

import 'update_download_service.dart';

/// statusAndProgress 会为暂停、失败等状态额外发送负进度，不能当成下载中。
UpdateDownloadEvent? mapBackgroundUpdate(TaskUpdate update) {
  if (update is TaskProgressUpdate) {
    if (!update.progress.isFinite ||
        update.progress < 0 ||
        update.progress > 1) {
      return null;
    }
    return UpdateDownloadEvent(
      taskId: update.task.taskId,
      status: UpdateDownloadStatus.downloading,
      progress: update.progress,
      downloadedBytes: update.expectedFileSize > 0
          ? (update.expectedFileSize * update.progress).round()
          : 0,
      totalBytes: update.expectedFileSize > 0 ? update.expectedFileSize : 0,
    );
  }
  final status = update as TaskStatusUpdate;
  return UpdateDownloadEvent(
    taskId: status.task.taskId,
    status: mapBackgroundStatus(status.status),
    errorMessage: status.exception?.description,
  );
}

UpdateDownloadStatus mapBackgroundStatus(TaskStatus status) => switch (status) {
  TaskStatus.enqueued ||
  TaskStatus.waitingToRetry => UpdateDownloadStatus.queued,
  TaskStatus.running => UpdateDownloadStatus.downloading,
  TaskStatus.paused => UpdateDownloadStatus.paused,
  TaskStatus.complete => UpdateDownloadStatus.complete,
  TaskStatus.notFound => UpdateDownloadStatus.notFound,
  TaskStatus.failed => UpdateDownloadStatus.failed,
  TaskStatus.canceled => UpdateDownloadStatus.cancelled,
};
