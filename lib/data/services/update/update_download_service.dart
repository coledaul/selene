import '../../../domain/models/app_release_asset.dart';
import '../../../domain/models/app_update_transfer.dart';

enum UpdateDownloadStatus {
  queued,
  downloading,
  paused,
  complete,
  notFound,
  failed,
  cancelled,
}

final class UpdateDownloadRequest {
  const UpdateDownloadRequest({
    required this.taskId,
    required this.version,
    required this.asset,
    required this.source,
    required this.uri,
    required this.retries,
    required this.priority,
  });

  final String taskId;
  final String version;
  final AppReleaseAsset asset;
  final UpdateDownloadSource source;
  final Uri uri;
  final int retries;
  final int priority;
}

final class UpdateDownloadEvent {
  const UpdateDownloadEvent({
    required this.taskId,
    required this.status,
    this.progress = 0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
  });

  final String taskId;
  final UpdateDownloadStatus status;
  final double progress;
  final int downloadedBytes;
  final int totalBytes;
  final String? errorMessage;
}

final class UpdateDownloadRecord {
  const UpdateDownloadRecord({
    required this.request,
    required this.status,
    required this.progress,
  });

  final UpdateDownloadRequest request;
  final UpdateDownloadStatus status;
  final double progress;
}

/// 与具体下载插件无关的更新任务传输合同。
abstract interface class UpdateDownloadService {
  bool get supported;
  Stream<UpdateDownloadEvent> get updates;

  Future<UpdateDownloadRecord?> initialize();
  Future<bool> enqueue(UpdateDownloadRequest request);
  Future<bool> pause(String taskId);
  Future<bool> resume(String taskId);
  Future<void> cancel(String taskId);
  Future<String?> filePath(String taskId);
  Future<void> remove(String taskId, {required bool deleteFile});
  Future<bool> openFile(String taskId, {required String mimeType});
  void dispose();
}

/// 非 Android 平台使用空实现，保留原有浏览器打开 Release 的行为。
final class UnsupportedUpdateDownloadService implements UpdateDownloadService {
  const UnsupportedUpdateDownloadService();

  @override
  bool get supported => false;

  @override
  Stream<UpdateDownloadEvent> get updates => const Stream.empty();

  @override
  Future<void> cancel(String taskId) async {}

  @override
  void dispose() {}

  @override
  Future<bool> enqueue(UpdateDownloadRequest request) async => false;

  @override
  Future<String?> filePath(String taskId) async => null;

  @override
  Future<UpdateDownloadRecord?> initialize() async => null;

  @override
  Future<bool> openFile(String taskId, {required String mimeType}) async =>
      false;

  @override
  Future<bool> pause(String taskId) async => false;

  @override
  Future<void> remove(String taskId, {required bool deleteFile}) async {}

  @override
  Future<bool> resume(String taskId) async => false;
}
