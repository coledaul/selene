import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/update/update_repository.dart';
import 'package:selene/data/repositories/update/update_transfer_controller.dart';
import 'package:selene/data/services/update/update_api_service.dart';
import 'package:selene/data/services/update/update_download_service.dart';
import 'package:selene/data/services/update/update_launcher_service.dart';
import 'package:selene/data/services/update/update_package_file_service.dart';
import 'package:selene/data/services/update/update_permission_service.dart';
import 'package:selene/data/services/update/update_preferences_service.dart';
import 'package:selene/data/services/update/update_source_service.dart';
import 'package:selene/domain/models/app_release_asset.dart';
import 'package:selene/domain/models/app_update_transfer.dart';
import 'package:selene/domain/models/app_version.dart';
import 'package:selene/utils/result.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test('每次冷启动可提示更新，旧的 24 小时时间戳不再限制提示', () async {
    final previous = SharedPreferencesAsyncPlatform.instance;
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          'last_version_check': DateTime.now().millisecondsSinceEpoch,
        });
    for (var launch = 0; launch < 2; launch++) {
      final repository = _repository(
        apiService: _FakeUpdateApiService(_version()),
        preferencesService: SharedPreferencesUpdateService(),
      );
      addTearDown(repository.dispose);
      expect(
        (await repository.check()).valueOrNull?.latestVersion,
        _version().latestVersion,
      );
    }
  });

  test('同次运行只自动检查一次，手动检查仍会发起请求', () async {
    final api = _FakeUpdateApiService(_version());
    final repository = _repository(apiService: api);
    addTearDown(repository.dispose);
    expect((await repository.check()).valueOrNull, isNotNull);
    expect((await repository.check()).valueOrNull, isNull);
    expect(api.checkCount, 1);
    expect(
      (await repository.check(respectPromptPolicy: false)).valueOrNull,
      isNotNull,
    );
    expect(api.checkCount, 2);
  });

  test('忽略只抑制对应版本的自动提示，手动检查及后续新版本仍可提示', () async {
    final previous = SharedPreferencesAsyncPlatform.instance;
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({});
    final preferences = SharedPreferencesUpdateService();
    await preferences.dismiss(_version().latestVersion);
    final ignored = _repository(
      apiService: _FakeUpdateApiService(_version()),
      preferencesService: preferences,
    );
    addTearDown(ignored.dispose);
    expect((await ignored.check()).valueOrNull, isNull);
    expect(
      (await ignored.check(respectPromptPolicy: false)).valueOrNull,
      isNotNull,
    );
    final newer = _repository(
      apiService: _FakeUpdateApiService(_version(latestVersion: '1.8.9')),
      preferencesService: preferences,
    );
    addTearDown(newer.dispose);
    expect((await newer.check()).valueOrNull?.latestVersion, '1.8.9');
  });

  test('暂停请求接受不代表已暂停，必须等待插件确认', () async {
    final download = _FakeUpdateDownloadService();
    final repository = _repository(
      apiService: _FakeUpdateApiService(_version()),
      downloadService: download,
    );
    addTearDown(repository.dispose);
    await repository.startDownload(_version());
    final id = download.requests.single.taskId;
    download.emit(
      UpdateDownloadEvent(
        taskId: id,
        status: UpdateDownloadStatus.downloading,
        progress: .4,
      ),
    );
    await _flushEvents();
    var finished = false;
    final pausing = repository.pause().then((value) {
      finished = true;
      return value;
    });
    await _flushEvents();
    expect(finished, isFalse);
    expect(repository.transfer.phase, UpdateTransferPhase.downloading);
    expect(
      (await repository.pause()).failureOrNull?.kind,
      FailureKind.conflict,
    );
    expect(
      (await repository.resume()).failureOrNull?.kind,
      FailureKind.conflict,
    );
    expect(
      (await repository.cancel()).failureOrNull?.kind,
      FailureKind.conflict,
    );
    expect(download.pauseCount, 1);
    download.emit(
      UpdateDownloadEvent(taskId: id, status: UpdateDownloadStatus.paused),
    );
    expect((await pausing).isSuccess, isTrue);
    expect(repository.transfer.phase, UpdateTransferPhase.paused);
    download.emit(
      UpdateDownloadEvent(
        taskId: id,
        status: UpdateDownloadStatus.downloading,
        progress: .4,
      ),
    );
    await _flushEvents();
    expect(repository.transfer.phase, UpdateTransferPhase.paused);
  });

  test('多轮暂停继续保持同一任务和进度，运行确认早于接口返回也不回退', () async {
    final record = _downloadRecord(_version());
    final download = _FakeUpdateDownloadService(initialRecord: record);
    final repository = _repository(
      apiService: _FakeUpdateApiService(_version()),
      downloadService: download,
    );
    addTearDown(repository.dispose);
    await repository.initialize();
    for (var i = 0; i < 20; i++) {
      final gate = Completer<bool>();
      download.resumeGate = gate;
      final resuming = repository.resume();
      download.emit(
        UpdateDownloadEvent(
          taskId: record.request.taskId,
          status: UpdateDownloadStatus.queued,
        ),
      );
      download.emit(
        UpdateDownloadEvent(
          taskId: record.request.taskId,
          status: UpdateDownloadStatus.downloading,
        ),
      );
      await _flushEvents();
      expect(repository.transfer.phase, UpdateTransferPhase.downloading);
      expect(
        (await repository.pause()).failureOrNull?.kind,
        FailureKind.conflict,
      );
      gate.complete(true);
      expect((await resuming).isSuccess, isTrue);
      expect(repository.transfer.phase, UpdateTransferPhase.downloading);
      expect(repository.transfer.progress, .5);
      final pausing = repository.pause();
      download.emit(
        UpdateDownloadEvent(
          taskId: record.request.taskId,
          status: UpdateDownloadStatus.paused,
        ),
      );
      expect((await pausing).isSuccess, isTrue);
      expect(repository.transfer.phase, UpdateTransferPhase.paused);
    }
    expect(download.pauseCount, 20);
    expect(download.requests, isEmpty);
    expect(download.removedTaskIds, isEmpty);
  });

  test('取消后同版本重试生成新任务，旧进度和完成事件无权覆盖', () async {
    final download = _FakeUpdateDownloadService();
    final repository = _repository(
      apiService: _FakeUpdateApiService(_version()),
      downloadService: download,
    );
    addTearDown(repository.dispose);
    await repository.startDownload(_version());
    final oldId = download.requests.single.taskId;
    await repository.cancel();
    await repository.startDownload(_version());
    final newId = download.requests.last.taskId;
    expect(newId, isNot(oldId));
    for (final status in UpdateDownloadStatus.values) {
      download.emit(
        UpdateDownloadEvent(taskId: oldId, status: status, progress: .8),
      );
    }
    await _flushEvents();
    expect(repository.transfer.taskId, newId);
    expect(repository.transfer.phase, UpdateTransferPhase.queued);
    expect(repository.transfer.progress, 0);
  });

  test('完成后晚到的进度与状态不能重复校验或回到下载中', () async {
    final download = _FakeUpdateDownloadService();
    final repository = _repository(
      apiService: _FakeUpdateApiService(_version()),
      downloadService: download,
    );
    addTearDown(repository.dispose);
    await repository.startDownload(_version());
    final id = download.requests.single.taskId;
    download.emit(
      UpdateDownloadEvent(taskId: id, status: UpdateDownloadStatus.complete),
    );
    await _flushEvents();
    for (final status in UpdateDownloadStatus.values) {
      download.emit(
        UpdateDownloadEvent(taskId: id, status: status, progress: .8),
      );
    }
    await _flushEvents();
    expect(repository.transfer.phase, UpdateTransferPhase.readyToInstall);
    expect(repository.transfer.progress, 1);
    expect(download.requests, hasLength(1));
  });

  test('暂停确认超时返回明确失败，不伪造暂停且释放操作锁', () async {
    final record = _downloadRecord(
      _version(),
      status: UpdateDownloadStatus.downloading,
    );
    final download = _FakeUpdateDownloadService(initialRecord: record);
    final controller = UpdateTransferController(
      downloadService: download,
      packageFileService: _FakeUpdatePackageFileService(valid: true),
      permissionService: _FakeUpdatePermissionService(
        UpdateInstallPermission.granted,
      ),
      sourceResolver: const UpdateSourceResolver(),
      actionTimeout: const Duration(milliseconds: 10),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    expect((await controller.pause()).failureOrNull?.kind, FailureKind.timeout);
    expect(controller.transfer.phase, UpdateTransferPhase.downloading);
    expect((await controller.cancel()).isSuccess, isTrue);
  });

  test('释放控制器解除未确认的暂停，不再发出状态通知', () async {
    final record = _downloadRecord(
      _version(),
      status: UpdateDownloadStatus.downloading,
    );
    final download = _FakeUpdateDownloadService(initialRecord: record);
    final repository = _repository(
      apiService: _FakeUpdateApiService(_version()),
      downloadService: download,
    );
    await repository.initialize();
    final pausing = repository.pause();
    await _flushEvents();
    repository.dispose();
    expect((await pausing).failureOrNull?.kind, FailureKind.cancellation);
  });

  test('继续接口晚返回不能把已完成的任务改回排队', () async {
    final record = _downloadRecord(_version());
    final gate = Completer<bool>();
    final download = _FakeUpdateDownloadService(initialRecord: record)
      ..resumeGate = gate;
    final repository = _repository(
      apiService: _FakeUpdateApiService(_version()),
      downloadService: download,
    );
    addTearDown(repository.dispose);
    await repository.initialize();
    final resumed = repository.resume();
    download.emit(
      UpdateDownloadEvent(
        taskId: record.request.taskId,
        status: UpdateDownloadStatus.complete,
        progress: 1,
      ),
    );
    await _flushEvents();
    expect(repository.transfer.phase, UpdateTransferPhase.readyToInstall);
    gate.complete(true);
    await resumed;
    expect(repository.transfer.phase, UpdateTransferPhase.readyToInstall);
  });

  test('恢复运行状态通知不能清零已经下载的进度', () async {
    final download = _FakeUpdateDownloadService();
    final repository = _repository(
      apiService: _FakeUpdateApiService(_version()),
      downloadService: download,
    );
    addTearDown(repository.dispose);
    await repository.startDownload(_version());
    final id = download.requests.single.taskId;
    download.emit(
      UpdateDownloadEvent(
        taskId: id,
        status: UpdateDownloadStatus.downloading,
        progress: .6,
      ),
    );
    await _flushEvents();
    download.emit(
      UpdateDownloadEvent(taskId: id, status: UpdateDownloadStatus.downloading),
    );
    await _flushEvents();
    expect(repository.transfer.progress, .6);
  });

  test('重复失败事件不会跳过直连兜底或把新任务标为失败', () async {
    final gate = Completer<void>();
    final download = _FakeUpdateDownloadService()..removeGate = gate;
    final repository = _repository(
      apiService: _FakeUpdateApiService(_version()),
      downloadService: download,
    );
    addTearDown(repository.dispose);
    await repository.startDownload(_version());
    final id = download.requests.single.taskId;
    download.emit(
      UpdateDownloadEvent(taskId: id, status: UpdateDownloadStatus.failed),
    );
    download.emit(
      UpdateDownloadEvent(taskId: id, status: UpdateDownloadStatus.failed),
    );
    await _flushEvents();
    expect(download.requests, hasLength(1));
    gate.complete();
    await _flushEvents();
    expect(download.requests, hasLength(2));
    expect(repository.transfer.phase, UpdateTransferPhase.queued);
  });

  test('新下载不受旧版保存的手选线路限制', () async {
    final previousPlatform = SharedPreferencesAsyncPlatform.instance;
    addTearDown(
      () => SharedPreferencesAsyncPlatform.instance = previousPlatform,
    );
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData(<String, Object>{
          'update_download_source': 'direct',
        });
    final download = _FakeUpdateDownloadService();
    final repository = _repository(
      apiService: _FakeUpdateApiService(_version()),
      preferencesService: SharedPreferencesUpdateService(),
      downloadService: download,
    );
    addTearDown(repository.dispose);

    expect((await repository.startDownload(_version())).isSuccess, isTrue);
    expect(download.requests.single.source, UpdateDownloadSource.proxy);
    expect(repository.transfer.requestedSource, UpdateDownloadSource.automatic);
  });

  test('已忽略的版本不会再次自动暴露给 UI', () async {
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

  test('全部下载线路失败后只显示可操作的提示，不展示插件内部地址', () async {
    final download = _FakeUpdateDownloadService();
    final repository = _repository(
      apiService: _FakeUpdateApiService(_version()),
      downloadService: download,
    );
    addTearDown(repository.dispose);
    await repository.startDownload(_version());
    for (var attempt = 0; attempt < 2; attempt++) {
      download.emit(
        UpdateDownloadEvent(
          taskId: download.requests.last.taskId,
          status: UpdateDownloadStatus.failed,
          errorMessage: 'HTTP 502: https://internal.example/package.apk',
        ),
      );
      await _flushEvents();
    }
    expect(repository.transfer.phase, UpdateTransferPhase.failed);
    expect(repository.transfer.errorMessage, '下载失败，请重试或使用浏览器下载');
    expect(download.requests, hasLength(2));
  });

  test('恢复旧版已暂停任务时保留文件和来源，不重新下载', () async {
    final record = _downloadRecord(_version());
    final download = _FakeUpdateDownloadService(initialRecord: record);
    final repository = _repository(
      apiService: _FakeUpdateApiService(_version()),
      downloadService: download,
    );
    addTearDown(repository.dispose);
    await repository.check(respectPromptPolicy: false);
    expect(repository.transfer.phase, UpdateTransferPhase.paused);
    expect(repository.transfer.activeSource, UpdateDownloadSource.direct);
    expect(repository.transfer.taskId, record.request.taskId);
    expect((await repository.resume()).isSuccess, isTrue);
    expect(download.requests, isEmpty);
    expect(download.removedTaskIds, isEmpty);
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
    expect(repository.transfer.errorMessage, '下载失败，请重试');
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
  int checkCount = 0;

  @override
  Future<Result<AppVersionInfo?>> check() async {
    checkCount++;
    return Success(value);
  }

  @override
  void dispose() {}
}

final class _FakeUpdatePreferencesService implements UpdatePreferencesService {
  _FakeUpdatePreferencesService({bool shouldPrompt = true})
    : _shouldPrompt = shouldPrompt;

  final bool _shouldPrompt;

  @override
  Future<void> dismiss(String version) async {}

  @override
  Future<bool> shouldPrompt(String version) async => _shouldPrompt;
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
  Completer<bool>? resumeGate;
  Completer<void>? removeGate;
  int pauseCount = 0;

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
  Future<bool> pause(String taskId) async {
    pauseCount++;
    return true;
  }

  @override
  Future<void> remove(String taskId, {required bool deleteFile}) async {
    final error = removeError;
    if (error != null) throw error;
    removedTaskIds.add(taskId);
    if (removeGate != null) await removeGate!.future;
  }

  @override
  Future<bool> resume(String taskId) async {
    if (resumeGate != null) return resumeGate!.future;
    emit(
      UpdateDownloadEvent(
        taskId: taskId,
        status: UpdateDownloadStatus.downloading,
      ),
    );
    return true;
  }
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
