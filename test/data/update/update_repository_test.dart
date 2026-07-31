import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/update/update_repository.dart';
import 'package:selene/data/services/update/update_api_service.dart';
import 'package:selene/data/services/update/update_download_service.dart';
import 'package:selene/data/services/update/update_launcher_service.dart';
import 'package:selene/data/services/update/update_package_file_service.dart';
import 'package:selene/data/services/update/update_permission_service.dart';
import 'package:selene/data/services/update/update_preferences_service.dart';
import 'package:selene/domain/models/app_release_asset.dart';
import 'package:selene/domain/models/app_update_transfer.dart';
import 'package:selene/domain/models/app_version.dart';
import 'package:selene/utils/result.dart';

void main() {
  test('已忽略或一天内提示过的版本不会再次暴露给 UI', () async {
    final repository = _repository(
      apiService: _FakeUpdateApiService(_version()),
      preferencesService: _FakeUpdatePreferencesService(shouldPrompt: false),
    );

    final result = await repository.check();

    expect(result.valueOrNull, isNull);
    expect(result.isSuccess, isTrue);
  });

  test('偏好存储失败会保留 storage 类型错误', () async {
    final repository = _repository(
      apiService: _FakeUpdateApiService(null),
      preferencesService: _ThrowingUpdatePreferencesService(),
    );

    final result = await repository.dismiss('1.1.0');

    expect(result.failureOrNull?.kind, FailureKind.storage);
  });

  test('自动线路加速地址失败后只回退一次 GitHub 直连并完成摘要校验', () async {
    final download = _FakeUpdateDownloadService();
    final verifier = _FakeUpdatePackageFileService(valid: true);
    final repository = _repository(
      apiService: _FakeUpdateApiService(_version()),
      downloadService: download,
      packageFileService: verifier,
    );
    await repository.initialize();

    expect((await repository.startDownload(_version())).isSuccess, isTrue);
    expect(download.requests.single.source, UpdateDownloadSource.proxy);
    expect(download.requests.single.uri.host, 'gh-proxy.com');
    expect(download.requests.single.retries, 0);
    expect(download.requests.single.priority, 0);

    download.emit(
      UpdateDownloadEvent(
        taskId: download.requests.single.taskId,
        status: UpdateDownloadStatus.failed,
        errorMessage: 'timeout',
      ),
    );
    await _flushEvents();

    expect(download.requests, hasLength(2));
    expect(download.requests.last.source, UpdateDownloadSource.direct);
    expect(download.requests.last.uri, _version().androidAsset!.downloadUri);
    expect(download.requests.last.retries, 2);

    download.emit(
      UpdateDownloadEvent(
        taskId: download.requests.last.taskId,
        status: UpdateDownloadStatus.complete,
        progress: 1,
      ),
    );
    await _flushEvents();

    expect(repository.transfer.phase, UpdateTransferPhase.readyToInstall);
    expect(verifier.verifiedAsset, _version().androidAsset);
  });

  test('通知权限被拒绝时降级普通后台任务而不强行启用 UIDT', () async {
    final download = _FakeUpdateDownloadService();
    final repository = _repository(
      apiService: _FakeUpdateApiService(_version()),
      downloadService: download,
      permissionService: _FakeUpdatePermissionService(
        UpdateInstallPermission.granted,
        notificationGranted: false,
      ),
    );

    await repository.startDownload(_version());

    expect(download.requests.single.priority, 5);
  });

  test('下载服务初始化失败时 startDownload 返回失败而不是抛出异常', () async {
    final repository = _repository(
      apiService: _FakeUpdateApiService(_version()),
      downloadService: _FakeUpdateDownloadService(
        initializeError: StateError('database unavailable'),
      ),
    );

    final result = await repository.startDownload(_version());

    expect(result.failureOrNull?.kind, FailureKind.storage);
    expect(result.failureOrNull?.message, '无法初始化更新下载');
  });

  test('开始新任务清理旧记录失败时返回失败并保留原状态', () async {
    final oldVersion = _version(latestVersion: '1.8.2');
    final record = _downloadRecord(
      oldVersion,
      status: UpdateDownloadStatus.failed,
    );
    final download = _FakeUpdateDownloadService(
      initialRecord: record,
      removeError: StateError('delete unavailable'),
    );
    final repository = _repository(
      apiService: _FakeUpdateApiService(_version()),
      downloadService: download,
    );

    final result = await repository.startDownload(_version());

    expect(result.failureOrNull?.kind, FailureKind.storage);
    expect(result.failureOrNull?.message, '无法清理旧版本更新包');
    expect(repository.transfer.taskId, record.request.taskId);
    expect(download.requests, isEmpty);
  });

  test('自动线路回退清理失败时进入明确失败状态且不产生未处理异常', () async {
    final download = _FakeUpdateDownloadService(
      removeError: StateError('delete unavailable'),
    );
    final repository = _repository(
      apiService: _FakeUpdateApiService(_version()),
      downloadService: download,
    );
    await repository.initialize();
    await repository.startDownload(_version());

    download.emit(
      UpdateDownloadEvent(
        taskId: download.requests.single.taskId,
        status: UpdateDownloadStatus.failed,
        errorMessage: 'timeout',
      ),
    );
    await _flushEvents();

    expect(repository.transfer.phase, UpdateTransferPhase.failed);
    expect(repository.transfer.errorMessage, '切换更新下载线路失败，请重试');
    expect(download.requests, hasLength(1));
  });

  test('未知来源权限被拒绝时保留已校验 APK 并允许重试', () async {
    final download = _FakeUpdateDownloadService();
    final permission = _FakeUpdatePermissionService(
      UpdateInstallPermission.denied,
    );
    final repository = _repository(
      apiService: _FakeUpdateApiService(_version()),
      downloadService: download,
      permissionService: permission,
    );
    await repository.initialize();
    await repository.startDownload(_version());
    download.emit(
      UpdateDownloadEvent(
        taskId: download.requests.single.taskId,
        status: UpdateDownloadStatus.complete,
        progress: 1,
      ),
    );
    await _flushEvents();

    final result = await repository.install();

    expect(result.failureOrNull?.kind, FailureKind.authorization);
    expect(repository.transfer.phase, UpdateTransferPhase.readyToInstall);
    expect(download.openedTaskIds, isEmpty);
    expect(download.removedTaskIds, isEmpty);
  });

  test('当前版本已是最新时清理上次更新包和任务记录', () async {
    final record = _downloadRecord(_version());
    final download = _FakeUpdateDownloadService(initialRecord: record);
    final repository = _repository(
      apiService: _FakeUpdateApiService(null),
      downloadService: download,
    );

    final result = await repository.check();

    expect(result.isSuccess, isTrue);
    expect(download.removedTaskIds, <String>[record.request.taskId]);
    expect(repository.transfer.phase, UpdateTransferPhase.idle);
  });

  test('检查到更高版本时清理旧版本更新包', () async {
    final oldVersion = _version();
    final record = _downloadRecord(oldVersion);
    final download = _FakeUpdateDownloadService(initialRecord: record);
    final repository = _repository(
      apiService: _FakeUpdateApiService(_version(latestVersion: '1.8.4')),
      downloadService: download,
    );

    final result = await repository.check();

    expect(result.valueOrNull?.latestVersion, '1.8.4');
    expect(download.removedTaskIds, <String>[record.request.taskId]);
    expect(repository.transfer.phase, UpdateTransferPhase.idle);
  });

  test('不支持应用内下载的平台继续通过 Launcher 打开 Release', () async {
    final launcher = _FakeUpdateLauncherService();
    final repository = _repository(
      apiService: _FakeUpdateApiService(_version()),
      downloadService: _FakeUpdateDownloadService(supported: false),
      launcherService: launcher,
    );

    final result = await repository.openRelease(_version());

    expect(result.isSuccess, isTrue);
    expect(launcher.opened, _version().releaseUri);
  });
}

DefaultUpdateRepository _repository({
  required UpdateApiService apiService,
  UpdatePreferencesService? preferencesService,
  UpdateDownloadService? downloadService,
  UpdatePackageVerifier? packageFileService,
  UpdatePermissionService? permissionService,
  UpdateLauncherService? launcherService,
}) => DefaultUpdateRepository(
  apiService: apiService,
  preferencesService: preferencesService ?? _FakeUpdatePreferencesService(),
  downloadService: downloadService ?? _FakeUpdateDownloadService(),
  packageFileService:
      packageFileService ?? _FakeUpdatePackageFileService(valid: true),
  permissionService:
      permissionService ??
      _FakeUpdatePermissionService(UpdateInstallPermission.granted),
  launcherService: launcherService ?? _FakeUpdateLauncherService(),
);

AppVersionInfo _version({String latestVersion = '1.8.3'}) => AppVersionInfo(
  currentVersion: '1.8.2',
  latestVersion: latestVersion,
  releaseNotes: '',
  releaseUri: Uri.parse(
    'https://github.com/coledaul/selene/releases/tag/v$latestVersion',
  ),
  androidAsset: AppReleaseAsset(
    fileName: 'selene-$latestVersion-armv8.apk',
    downloadUri: Uri.parse(
      'https://github.com/coledaul/selene/releases/download/'
      'v$latestVersion/selene-$latestVersion-armv8.apk',
    ),
    size: 66,
    sha256: 'a' * 64,
    architecture: AndroidArchitecture.arm64,
  ),
);

UpdateDownloadRecord _downloadRecord(
  AppVersionInfo versionInfo, {
  UpdateDownloadStatus status = UpdateDownloadStatus.paused,
}) => UpdateDownloadRecord(
  request: UpdateDownloadRequest(
    taskId: 'restored-update',
    version: versionInfo.latestVersion,
    asset: versionInfo.androidAsset!,
    source: UpdateDownloadSource.direct,
    uri: versionInfo.androidAsset!.downloadUri,
    retries: 0,
    priority: 0,
  ),
  status: status,
  progress: 0.5,
);

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

final class _FakeUpdateApiService implements UpdateApiService {
  _FakeUpdateApiService(this.value);

  final AppVersionInfo? value;

  @override
  Future<Result<AppVersionInfo?>> check() async => Success(value);

  @override
  void dispose() {}
}

final class _FakeUpdatePreferencesService implements UpdatePreferencesService {
  _FakeUpdatePreferencesService({bool shouldPrompt = true})
    : _shouldPrompt = shouldPrompt;

  final bool _shouldPrompt;
  UpdateDownloadSource source = UpdateDownloadSource.automatic;

  @override
  Future<void> dismiss(String version) async {}

  @override
  Future<UpdateDownloadSource> loadDownloadSource() async => source;

  @override
  Future<void> saveDownloadSource(UpdateDownloadSource value) async {
    source = value;
  }

  @override
  Future<bool> shouldPrompt(String version, DateTime now) async =>
      _shouldPrompt;
}

final class _ThrowingUpdatePreferencesService
    implements UpdatePreferencesService {
  @override
  Future<void> dismiss(String version) => throw StateError('unavailable');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeUpdateDownloadService implements UpdateDownloadService {
  _FakeUpdateDownloadService({
    this.supported = true,
    this.initialRecord,
    this.initializeError,
    this.removeError,
  });

  final StreamController<UpdateDownloadEvent> _updates =
      StreamController<UpdateDownloadEvent>.broadcast();
  final List<UpdateDownloadRequest> requests = <UpdateDownloadRequest>[];
  final List<String> openedTaskIds = <String>[];
  final List<String> removedTaskIds = <String>[];

  @override
  final bool supported;
  final UpdateDownloadRecord? initialRecord;
  final Object? initializeError;
  final Object? removeError;

  @override
  Stream<UpdateDownloadEvent> get updates => _updates.stream;

  void emit(UpdateDownloadEvent event) => _updates.add(event);

  @override
  Future<void> cancel(String taskId) async {}

  @override
  void dispose() => _updates.close();

  @override
  Future<bool> enqueue(UpdateDownloadRequest request) async {
    requests.add(request);
    return true;
  }

  @override
  Future<String?> filePath(String taskId) async => '/tmp/$taskId.apk';

  @override
  Future<UpdateDownloadRecord?> initialize() async {
    final error = initializeError;
    if (error != null) throw error;
    return initialRecord;
  }

  @override
  Future<bool> openFile(String taskId, {required String mimeType}) async {
    openedTaskIds.add(taskId);
    return true;
  }

  @override
  Future<bool> pause(String taskId) async => true;

  @override
  Future<void> remove(String taskId, {required bool deleteFile}) async {
    final error = removeError;
    if (error != null) throw error;
    removedTaskIds.add(taskId);
  }

  @override
  Future<bool> resume(String taskId) async => true;
}

final class _FakeUpdatePackageFileService implements UpdatePackageVerifier {
  _FakeUpdatePackageFileService({required this.valid});

  final bool valid;
  AppReleaseAsset? verifiedAsset;

  @override
  Future<bool> verify(String filePath, AppReleaseAsset asset) async {
    verifiedAsset = asset;
    return valid;
  }
}

final class _FakeUpdatePermissionService implements UpdatePermissionService {
  _FakeUpdatePermissionService(
    this.permission, {
    this.notificationGranted = true,
  });

  final UpdateInstallPermission permission;
  final bool notificationGranted;

  @override
  Future<UpdateInstallPermission> ensureInstallPermission() async => permission;

  @override
  Future<bool> requestNotificationPermission() async => notificationGranted;
}

final class _FakeUpdateLauncherService implements UpdateLauncherService {
  Uri? opened;

  @override
  Future<bool> open(Uri uri) async {
    opened = uri;
    return true;
  }
}
