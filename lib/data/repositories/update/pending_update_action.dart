import 'dart:async';

import '../../services/update/update_download_service.dart';

/// 插件请求被接受与任务真正暂停/恢复是两个时刻，等待确认期间不能反向操作。
final class PendingUpdateAction {
  PendingUpdateAction({required this.taskId, required this.target});

  final String taskId;
  final UpdateDownloadStatus target;
  final _confirmation = Completer<UpdateDownloadStatus>();

  Future<UpdateDownloadStatus> get confirmed => _confirmation.future;

  void observe(UpdateDownloadEvent event) {
    if (event.taskId != taskId ||
        (event.status == UpdateDownloadStatus.downloading &&
            event.progress != null)) {
      return;
    }
    if (event.status == target ||
        const {
          UpdateDownloadStatus.complete,
          UpdateDownloadStatus.failed,
          UpdateDownloadStatus.notFound,
          UpdateDownloadStatus.cancelled,
        }.contains(event.status)) {
      if (!_confirmation.isCompleted) _confirmation.complete(event.status);
    }
  }

  void cancel() {
    if (!_confirmation.isCompleted) {
      _confirmation.complete(UpdateDownloadStatus.cancelled);
    }
  }
}
