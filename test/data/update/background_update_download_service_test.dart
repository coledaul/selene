import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/services/update/background_update_download_service.dart';
import 'package:selene/data/services/update/background_update_event_mapper.dart';
import 'package:selene/data/services/update/update_download_service.dart';
import 'package:selene/data/services/update/update_resume_capability_store.dart';
import 'package:selene/domain/models/app_release_asset.dart';
import 'package:selene/domain/models/app_update_transfer.dart';

void main() {
  final task = DownloadTask(url: 'https://example.com/update.apk');

  test('负进度状态哨兵和无效进度不转换成下载事件', () {
    for (final progress in [
      -1.0,
      -2.0,
      -3.0,
      -4.0,
      -5.0,
      double.nan,
      double.infinity,
      1.1,
    ]) {
      expect(mapBackgroundUpdate(TaskProgressUpdate(task, progress)), isNull);
    }
  });

  test('状态事件与真实零进度区分，暂停和终态只由状态事件表达', () {
    for (final status in TaskStatus.values) {
      final event = mapBackgroundUpdate(TaskStatusUpdate(task, status))!;
      expect(event.progress, isNull);
      expect(event.status, mapBackgroundStatus(status));
    }
    final zero = mapBackgroundUpdate(TaskProgressUpdate(task, 0))!;
    expect(zero.progress, 0);
    final progress = mapBackgroundUpdate(TaskProgressUpdate(task, .5, 100))!;
    expect(progress.status, UpdateDownloadStatus.downloading);
    expect(progress.downloadedBytes, 50);
    expect(progress.totalBytes, 100);
  });

  for (final resumable in [false, true]) {
    test('暂停前确认来源可续传，resumable=$resumable', () async {
      final downloader = _Downloader();
      final store = _CapabilityStore();
      final service = BackgroundUpdateDownloadService(
        downloader: downloader,
        capabilityStore: store,
      );
      addTearDown(service.dispose);
      await service.enqueue(_request());
      final pausing = service.pause('task');
      await Future<void>.delayed(Duration.zero);
      expect(downloader.pauseCount, 0);
      downloader.resumable.complete(resumable);
      expect(await pausing, resumable);
      expect(downloader.pauseCount, resumable ? 1 : 0);
      await Future<void>.delayed(Duration.zero);
      expect(store.values['task'], resumable);
    });
  }

  test('释放服务后可续传检查晚返回不能再暂停原生任务', () async {
    final downloader = _Downloader();
    final store = _CapabilityStore();
    final service = BackgroundUpdateDownloadService(
      downloader: downloader,
      capabilityStore: store,
    );
    await service.enqueue(_request());
    final pausing = service.pause('task');
    await Future<void>.delayed(Duration.zero);
    service.dispose();
    downloader.resumable.complete(true);
    expect(await pausing, isFalse);
    expect(downloader.pauseCount, 0);
    expect(store.values, isEmpty);
  });

  testWidgets('能力确认超时明确失败，晚到结果不触发原生暂停', (tester) async {
    final store = _CapabilityStore();
    final downloader = _Downloader();
    final service = BackgroundUpdateDownloadService(
      downloader: downloader,
      capabilityStore: store,
    );
    addTearDown(service.dispose);
    await service.enqueue(_request());
    final failure = expectLater(
      service.pause('task'),
      throwsA(isA<TimeoutException>()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    await failure;
    downloader.resumable.complete(true);
    await tester.pump();
    expect(downloader.pauseCount, 0);
  });

  testWidgets('被系统终止后重新调度的任务重新确认能力，不沿用旧支持记录', (tester) async {
    final task = DownloadTask(
      taskId: 'task',
      url: 'https://example.com/update.apk',
      group: BackgroundUpdateDownloadService.group,
    );
    final store = _CapabilityStore()..values['task'] = true;
    final downloader = _Downloader(restoredTask: task)
      ..rescheduledTasks = [task];
    downloader.resumable.complete(false);
    final service = BackgroundUpdateDownloadService(
      downloader: downloader,
      capabilityStore: store,
    );
    addTearDown(service.dispose);
    await service.initialize();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(store.values['task'], isFalse);
    expect(await service.pause('task'), isFalse);
    expect(downloader.pauseCount, 0);
  });

  testWidgets('插件自动重试进入运行后记录新能力，并同步最新任务快照', (tester) async {
    final events = StreamController<TaskUpdate>();
    addTearDown(events.close);
    final store = _CapabilityStore();
    final downloader = _Downloader(eventStream: events.stream);
    final service = BackgroundUpdateDownloadService(
      downloader: downloader,
      capabilityStore: store,
    );
    addTearDown(service.dispose);
    await service.initialize();
    await tester.pump(const Duration(seconds: 5));
    await service.enqueue(_request(retries: 2));
    downloader.resumable.complete(true);
    await tester.pump();
    expect(store.attempts['task'], 2);
    final retryTask = downloader.lastTask!.copyWith(retriesRemaining: 1);
    downloader.resumable = Completer<bool>()..complete(false);
    events.add(TaskStatusUpdate(retryTask, TaskStatus.running));
    await tester.pump();
    expect(store.attempts['task'], 1);
    expect(store.values['task'], isFalse);
    expect(await service.pause('task'), isFalse);
    expect(downloader.pauseCount, 0);
  });

  test('后台任务冷恢复后使用原下载确认的能力，不把插件缺失记录当作不支持', () async {
    final store = _CapabilityStore();
    final original = _Downloader();
    final first = BackgroundUpdateDownloadService(
      downloader: original,
      capabilityStore: store,
    );
    await first.enqueue(_request());
    original.resumable.complete(true);
    await Future<void>.delayed(Duration.zero);
    expect(store.values['task'], isTrue);
    first.dispose();

    final restored = _Downloader(restoredTask: original.lastTask);
    restored.resumable.complete(false); // 新 Dart 实例没有插件能力 Completer。
    final second = BackgroundUpdateDownloadService(
      downloader: restored,
      capabilityStore: store,
    );
    addTearDown(second.dispose);
    expect(await second.pause('task'), isTrue);
    expect(restored.pauseCount, 1);
  });

  for (final capability in <bool?>[null, false]) {
    test('恢复任务没有可靠续传记录时保留下载，capability=$capability', () async {
      final store = _CapabilityStore();
      if (capability != null) store.values['task'] = capability;
      final downloader = _Downloader(
        restoredTask: DownloadTask(
          taskId: 'task',
          url: 'https://example.com/update.apk',
        ),
      );
      downloader.resumable.complete(false);
      final service = BackgroundUpdateDownloadService(
        downloader: downloader,
        capabilityStore: store,
      );
      addTearDown(service.dispose);
      expect(await service.pause('task'), isFalse);
      expect(downloader.pauseCount, 0);
      expect(downloader.cancelCount, 0);
    });
  }

  test('本次任务明确不支持时不能使用旧能力记录覆盖', () async {
    final store = _CapabilityStore()..values['task'] = true;
    final downloader = _Downloader();
    final service = BackgroundUpdateDownloadService(
      downloader: downloader,
      capabilityStore: store,
    );
    addTearDown(service.dispose);
    await service.enqueue(_request());
    expect(store.values, isEmpty);
    downloader.resumable.complete(false);
    expect(await service.pause('task'), isFalse);
    expect(downloader.pauseCount, 0);
    expect(store.readCount, 0);
  });

  test('冷恢复按当前重试次数读取记录，不把旧连接的能力用于自动重试', () async {
    final task = DownloadTask(
      taskId: 'task',
      url: 'https://example.com/update.apk',
      retries: 2,
    );
    final store = _CapabilityStore()
      ..values['task'] = true
      ..attempts['task'] = 2;
    final downloader = _Downloader(restoredTask: task);
    downloader.resumable.complete(false);
    final service = BackgroundUpdateDownloadService(
      downloader: downloader,
      capabilityStore: store,
    );
    addTearDown(service.dispose);
    expect(await service.pause('task'), isTrue);
    task.decreaseRetriesRemaining();
    expect(await service.pause('task'), isFalse);
    expect(downloader.pauseCount, 1);
  });

  testWidgets('取消后晚到的运行事件和能力确认不能重新留下旧记录', (tester) async {
    final events = StreamController<TaskUpdate>();
    addTearDown(events.close);
    final store = _CapabilityStore();
    final downloader = _Downloader(eventStream: events.stream);
    final service = BackgroundUpdateDownloadService(
      downloader: downloader,
      capabilityStore: store,
    );
    addTearDown(service.dispose);
    await service.initialize();
    await tester.pump(const Duration(seconds: 5));
    await service.enqueue(_request());
    await service.cancel('task');
    downloader.resumable.complete(true);
    events.add(TaskStatusUpdate(downloader.lastTask!, TaskStatus.running));
    await tester.pump();
    expect(store.values, isEmpty);
    expect(downloader.cancelCount, 1);
  });

  test('取消等待正在落盘的记录后再删除，不遗留支持续传的旧标记', () async {
    final store = _CapabilityStore()..pendingWrite = Completer<void>();
    final downloader = _Downloader();
    final service = BackgroundUpdateDownloadService(
      downloader: downloader,
      capabilityStore: store,
    );
    addTearDown(service.dispose);
    await service.enqueue(_request());
    downloader.resumable.complete(true);
    await Future<void>.delayed(Duration.zero);
    final cancelling = service.cancel('task');
    store.pendingWrite!.complete();
    await cancelling;
    expect(store.values, isEmpty);
    expect(downloader.cancelCount, 1);
  });

  test('能力记录写入失败不终止下载，也不影响后续取消清理', () async {
    final store = _CapabilityStore()..writeError = StateError('写入失败');
    final downloader = _Downloader();
    final service = BackgroundUpdateDownloadService(
      downloader: downloader,
      capabilityStore: store,
    );
    addTearDown(service.dispose);
    await service.enqueue(_request());
    downloader.resumable.complete(true);
    await Future<void>.delayed(Duration.zero);
    expect(await service.pause('task'), isTrue);
    await service.cancel('task');
    expect(store.values, isEmpty);
    expect(downloader.cancelCount, 1);
  });

  test('删除能力记录失败仍发送取消，且显式报告清理失败', () async {
    final store = _CapabilityStore();
    final downloader = _Downloader();
    final service = BackgroundUpdateDownloadService(
      downloader: downloader,
      capabilityStore: store,
    );
    addTearDown(service.dispose);
    await service.enqueue(_request());
    store.removeError = StateError('删除失败');
    await expectLater(service.cancel('task'), throwsStateError);
    expect(downloader.cancelCount, 1);
  });

  test('能力读取失败显式返回异常，不向原生发送暂停', () async {
    final store = _CapabilityStore()..readError = StateError('存储读取失败');
    final downloader = _Downloader(
      restoredTask: DownloadTask(
        taskId: 'task',
        url: 'https://example.com/update.apk',
      ),
    );
    downloader.resumable.complete(false);
    final service = BackgroundUpdateDownloadService(
      downloader: downloader,
      capabilityStore: store,
    );
    addTearDown(service.dispose);
    await expectLater(service.pause('task'), throwsStateError);
    expect(downloader.pauseCount, 0);
  });

  test('释放服务后能力读取晚返回不能再暂停原生任务', () async {
    final store = _CapabilityStore()..pendingRead = Completer<bool?>();
    final downloader = _Downloader(
      restoredTask: DownloadTask(
        taskId: 'task',
        url: 'https://example.com/update.apk',
      ),
    );
    downloader.resumable.complete(false);
    final service = BackgroundUpdateDownloadService(
      downloader: downloader,
      capabilityStore: store,
    );
    final pausing = service.pause('task');
    await Future<void>.delayed(Duration.zero);
    service.dispose();
    store.pendingRead!.complete(true);
    expect(await pausing, isFalse);
    expect(downloader.pauseCount, 0);
  });

  test('恢复成功后重新记录本次能力，恢复失败不伪造支持', () async {
    for (final accepted in [false, true]) {
      final store = _CapabilityStore()..values['task'] = true;
      final downloader = _Downloader(
        restoredTask: DownloadTask(
          taskId: 'task',
          url: 'https://example.com/update.apk',
        ),
      )..resumeAccepted = accepted;
      final service = BackgroundUpdateDownloadService(
        downloader: downloader,
        capabilityStore: store,
      );
      addTearDown(service.dispose);
      expect(await service.resume('task'), accepted);
      expect(store.values, isEmpty);
      downloader.resumable.complete(true);
      await Future<void>.delayed(Duration.zero);
      expect(store.values['task'], accepted ? true : null);
    }
  });
}

UpdateDownloadRequest _request({int retries = 0}) => UpdateDownloadRequest(
  taskId: 'task',
  version: '1.8.8',
  asset: AppReleaseAsset(
    fileName: 'selene.apk',
    downloadUri: Uri.parse('https://example.com/update.apk'),
    size: 100,
    sha256: 'a' * 64,
    architecture: AndroidArchitecture.arm64,
  ),
  source: UpdateDownloadSource.direct,
  uri: Uri.parse('https://example.com/update.apk'),
  retries: retries,
  priority: 5,
);

final class _Downloader implements FileDownloader {
  _Downloader({
    DownloadTask? restoredTask,
    Stream<TaskUpdate> eventStream = const Stream.empty(),
  }) : database = _Database(restoredTask),
       updates = eventStream;

  @override
  final Database database;
  var resumable = Completer<bool>();
  int pauseCount = 0;
  int cancelCount = 0;
  bool resumeAccepted = true;
  DownloadTask? lastTask;
  List<Task> rescheduledTasks = [];

  @override
  final Stream<TaskUpdate> updates;

  @override
  Future<List<(String, String)>> configure({
    dynamic globalConfig,
    dynamic androidConfig,
    dynamic iOSConfig,
    dynamic desktopConfig,
  }) async => [];

  @override
  FileDownloader configureNotificationForGroup(
    String group, {
    TaskNotification? running,
    TaskNotification? complete,
    TaskNotification? error,
    TaskNotification? paused,
    TaskNotification? canceled,
    bool progressBar = false,
    bool tapOpensFile = false,
    String groupNotificationId = '',
  }) => this;

  @override
  Future<FileDownloader> trackTasksInGroup(
    String group, {
    bool markDownloadedComplete = true,
  }) async => this;

  @override
  Future<void> resumeFromBackground() async {}

  @override
  Future<(List<Task>, List<Task>)> rescheduleKilledTasks() async =>
      (rescheduledTasks, <Task>[]);

  @override
  Future<bool> enqueue(Task task) async {
    lastTask = task as DownloadTask;
    return true;
  }

  @override
  Future<bool> resume(Task task) async => resumeAccepted;

  @override
  Future<bool> cancelTaskWithId(String taskId) async {
    cancelCount++;
    return true;
  }

  @override
  Future<bool> taskCanResume(Task task) => resumable.future;

  @override
  Future<bool> pause(DownloadTask task) async {
    pauseCount++;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Database implements Database {
  _Database(this.task);
  final DownloadTask? task;

  @override
  Future<List<TaskRecord>> allRecords({String? group}) async {
    final current = task;
    return current == null
        ? []
        : [TaskRecord(current, TaskStatus.running, .5, 100)];
  }

  @override
  Future<TaskRecord?> recordForId(String taskId) async {
    final current = task;
    if (current == null || current.taskId != taskId) return null;
    return TaskRecord(current, TaskStatus.running, .5, 100);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _CapabilityStore implements UpdateResumeCapabilityStore {
  final values = <String, bool>{};
  final attempts = <String, int>{};
  int readCount = 0;
  Object? readError;
  Object? writeError;
  Object? removeError;
  Completer<bool?>? pendingRead;
  Completer<void>? pendingWrite;

  @override
  Future<bool?> read(String taskId, {int retriesRemaining = 0}) async {
    readCount++;
    if (readError case final error?) throw error;
    if ((attempts[taskId] ?? 0) != retriesRemaining) return null;
    return pendingRead == null ? values[taskId] : await pendingRead!.future;
  }

  @override
  Future<void> write(
    String taskId,
    bool supported, {
    int retriesRemaining = 0,
  }) async {
    if (writeError case final error?) throw error;
    if (pendingWrite != null) await pendingWrite!.future;
    values[taskId] = supported;
    attempts[taskId] = retriesRemaining;
  }

  @override
  Future<void> remove(String taskId) async {
    if (removeError case final error?) throw error;
    values.remove(taskId);
    attempts.remove(taskId);
  }
}
