import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/dlna_device_repository.dart';
import 'package:selene/domain/models/dlna_device.dart';
import 'package:selene/ui/player/view_models/dlna_cast_view_model.dart';
import 'package:selene/utils/result.dart';

void main() {
  late _FakeDlnaDeviceRepository repository;
  late DlnaCastViewModel viewModel;
  var viewModelDisposed = false;

  setUp(() {
    viewModelDisposed = false;
    repository = _FakeDlnaDeviceRepository();
    viewModel = DlnaCastViewModel(
      repository: repository,
      playbackPollInterval: const Duration(hours: 1),
    );
  });

  tearDown(() async {
    if (!viewModelDisposed) viewModel.dispose();
    await repository.dispose();
  });

  test('最近投屏设备读取成功后发布独立状态，失败不覆盖已有记录', () async {
    const device = RecentDlnaDevice(
      endpoint: 'http://192.168.1.20:1400',
      friendlyName: '客厅电视',
      deviceType: 'renderer',
    );
    repository.loadResult = const Success<RecentDlnaDevice?>(device);

    expect(await viewModel.loadRecentDevice(), isA<Success<void>>());
    expect(viewModel.recentDevice, device);

    repository.loadResult = const FailureResult<RecentDlnaDevice?>(
      AppFailure(kind: FailureKind.storage, message: '读取失败'),
    );
    final result = await viewModel.loadRecentDevice();

    expect(result, isA<FailureResult<void>>());
    expect(viewModel.recentDevice, device);
  });

  test('最近投屏设备仅在持久化成功后更新', () async {
    const first = RecentDlnaDevice(
      endpoint: 'http://192.168.1.20:1400',
      friendlyName: '客厅电视',
      deviceType: 'renderer',
    );
    const second = RecentDlnaDevice(
      endpoint: 'http://192.168.1.21:1400',
      friendlyName: '卧室电视',
      deviceType: 'renderer',
    );

    expect(await viewModel.rememberDevice(first), isA<Success<void>>());
    expect(viewModel.recentDevice, first);

    repository.saveFailure = const AppFailure(
      kind: FailureKind.storage,
      message: '保存失败',
    );
    final result = await viewModel.rememberDevice(second);

    expect(result, isA<FailureResult<void>>());
    expect(viewModel.recentDevice, first);
  });

  test('扫描结果保持 Repository 顺序且刷新会重新启动扫描', () async {
    expect(await viewModel.startScanning(), isA<Success<void>>());
    repository.emit(<String, DiscoveredDlnaDevice>{
      'device-b': _device('device-b'),
      'device-a': _device('device-a'),
    });

    expect(viewModel.devices.keys, <String>['device-b', 'device-a']);
    expect(viewModel.scanStatus, '发现 2 个设备');

    expect(await viewModel.refreshScanning(), isA<Success<void>>());
    expect(repository.startCalls, 2);
    expect(repository.stopCalls, 1);
    expect(viewModel.devices, isEmpty);
  });

  test('DLNA 状态轮询串行执行，慢请求期间不会重入', () async {
    viewModel.dispose();
    await repository.dispose();
    repository = _FakeDlnaDeviceRepository();
    viewModel = DlnaCastViewModel(
      repository: repository,
      playbackPollInterval: const Duration(milliseconds: 5),
    );
    final gate = Completer<Result<DlnaPlaybackSnapshot>>();
    repository.statusGates.add(gate);

    viewModel.startPlaybackMonitoring(_device('device-a'));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(repository.statusCalls, 1);
    expect(repository.maxConcurrentStatusCalls, 1);

    gate.complete(const Success<DlnaPlaybackSnapshot>(_playingSnapshot));
    await Future<void>.delayed(const Duration(milliseconds: 15));

    expect(repository.statusCalls, greaterThan(1));
    expect(repository.maxConcurrentStatusCalls, 1);
  });

  test('切换设备后旧轮询的延迟响应不得覆盖新设备状态', () async {
    final firstGate = Completer<Result<DlnaPlaybackSnapshot>>();
    final secondGate = Completer<Result<DlnaPlaybackSnapshot>>();
    repository.statusGates.addAll(<Completer<Result<DlnaPlaybackSnapshot>>>[
      firstGate,
      secondGate,
    ]);
    final first = _device('device-a');
    final second = _device('device-b');

    viewModel.startPlaybackMonitoring(first);
    await Future<void>.delayed(Duration.zero);
    viewModel.startPlaybackMonitoring(second);
    await Future<void>.delayed(Duration.zero);

    secondGate.complete(
      const Success<DlnaPlaybackSnapshot>(
        DlnaPlaybackSnapshot(
          position: Duration(seconds: 20),
          duration: Duration(minutes: 2),
          playing: true,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.playbackState.deviceId, second.id);
    expect(viewModel.playbackState.position, const Duration(seconds: 20));

    firstGate.complete(
      const Success<DlnaPlaybackSnapshot>(
        DlnaPlaybackSnapshot(
          position: Duration(seconds: 90),
          duration: Duration(minutes: 2),
          playing: true,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.playbackState.deviceId, second.id);
    expect(viewModel.playbackState.position, const Duration(seconds: 20));
  });

  test('DLNA 控制命令失败返回 Result 并发布可见错误', () async {
    final device = _device('device-a');
    viewModel.startPlaybackMonitoring(device);
    await Future<void>.delayed(Duration.zero);
    repository.pauseFailure = const AppFailure(
      kind: FailureKind.network,
      message: '暂停失败',
    );

    final result = await viewModel.togglePlayback();

    expect(result, isA<FailureResult<void>>());
    expect(viewModel.playbackState.failure?.message, '暂停失败');
    expect(viewModel.playbackState.playing, isTrue);
  });

  test('控制命令开始前已发出的轮询响应不得覆盖命令结果', () async {
    viewModel.dispose();
    await repository.dispose();
    repository = _FakeDlnaDeviceRepository();
    viewModel = DlnaCastViewModel(
      repository: repository,
      playbackPollInterval: const Duration(milliseconds: 5),
    );
    final device = _device('device-a');
    viewModel.startPlaybackMonitoring(device);
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.playbackState.playing, isTrue);

    final stalePoll = Completer<Result<DlnaPlaybackSnapshot>>();
    repository.statusGates.add(stalePoll);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final pause = await viewModel.togglePlayback();
    expect(pause, isA<Success<void>>());
    expect(viewModel.playbackState.playing, isFalse);

    stalePoll.complete(const Success<DlnaPlaybackSnapshot>(_playingSnapshot));
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.playbackState.playing, isFalse);
  });

  test('播放完成必须先等待暂停确认，再发布 completed', () async {
    final status = Completer<Result<DlnaPlaybackSnapshot>>();
    final pause = Completer<Result<void>>();
    repository
      ..statusGates.add(status)
      ..pauseGate = pause;
    viewModel.startPlaybackMonitoring(_device('device-a'));
    await Future<void>.delayed(Duration.zero);

    status.complete(
      const Success<DlnaPlaybackSnapshot>(
        DlnaPlaybackSnapshot(
          position: Duration(minutes: 2),
          duration: Duration(minutes: 2),
          playing: true,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.playbackState.completed, isFalse);
    pause.complete(const Success<void>(null));
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.playbackState.completed, isTrue);
    expect(viewModel.playbackState.playing, isFalse);
  });

  test('续播跳转成功后首次 ready 直接发布目标位置', () async {
    final device = _device('device-a');
    viewModel.startPlaybackMonitoring(
      device,
      resumePosition: const Duration(seconds: 45),
    );
    await Future<void>.delayed(Duration.zero);

    expect(repository.seekTargets, <Duration>[const Duration(seconds: 45)]);
    expect(viewModel.playbackState.loading, isFalse);
    expect(viewModel.playbackState.position, const Duration(seconds: 45));
  });

  test('切换设备时旧命令未完成，新设备仍会在旧命令收尾后启动轮询', () async {
    final first = _device('device-a');
    final second = _device('device-b');
    viewModel.startPlaybackMonitoring(first);
    await Future<void>.delayed(Duration.zero);
    final pause = Completer<Result<void>>();
    repository.pauseGate = pause;
    final oldCommand = viewModel.togglePlayback();
    await Future<void>.delayed(Duration.zero);

    viewModel.startPlaybackMonitoring(second);
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.playbackState.loading, isTrue);

    pause.complete(const Success<void>(null));
    expect(await oldCommand, isA<FailureResult<void>>());
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.playbackState.deviceId, second.id);
    expect(viewModel.playbackState.loading, isFalse);
    expect(viewModel.playbackState.position, _playingSnapshot.position);
  });

  test('释放一个页面 ViewModel 只销毁自己拥有的扫描会话', () async {
    final otherRepository = _FakeDlnaDeviceRepository();
    final otherViewModel = DlnaCastViewModel(repository: otherRepository);
    addTearDown(() async {
      otherViewModel.dispose();
      await otherRepository.dispose();
    });
    await viewModel.startScanning();
    await otherViewModel.startScanning();

    viewModel.dispose();
    viewModelDisposed = true;
    await repository.dispose();

    expect(repository.disposed, isTrue);
    expect(otherRepository.disposed, isFalse);
    otherRepository.emit(<String, DiscoveredDlnaDevice>{
      'device-b': _device('device-b'),
    });
    expect(otherViewModel.devices.keys, <String>['device-b']);
  });
}

const _playingSnapshot = DlnaPlaybackSnapshot(
  position: Duration(seconds: 10),
  duration: Duration(minutes: 2),
  playing: true,
);

DiscoveredDlnaDevice _device(String id) => DiscoveredDlnaDevice(
  id: id,
  endpoint: 'http://192.168.1.20:1400/$id',
  friendlyName: id,
  deviceType: 'urn:schemas-upnp-org:device:MediaRenderer:1',
  activeTime: DateTime(2026),
);

final class _FakeDlnaDeviceRepository implements DlnaDeviceRepository {
  final StreamController<Map<String, DiscoveredDlnaDevice>> _devices =
      StreamController<Map<String, DiscoveredDlnaDevice>>.broadcast(sync: true);
  final List<Completer<Result<DlnaPlaybackSnapshot>>> statusGates =
      <Completer<Result<DlnaPlaybackSnapshot>>>[];
  Result<RecentDlnaDevice?> loadResult = const Success<RecentDlnaDevice?>(null);
  AppFailure? saveFailure;
  AppFailure? pauseFailure;
  Completer<Result<void>>? pauseGate;
  int startCalls = 0;
  int stopCalls = 0;
  int statusCalls = 0;
  int concurrentStatusCalls = 0;
  int maxConcurrentStatusCalls = 0;
  final List<Duration> seekTargets = <Duration>[];
  bool _disposed = false;
  Future<void>? _disposeFuture;

  bool get disposed => _disposed;

  @override
  Stream<Map<String, DiscoveredDlnaDevice>> get devices => _devices.stream;

  @override
  Future<Result<RecentDlnaDevice?>> loadRecent() async => loadResult;

  @override
  Future<Result<void>> saveRecent(RecentDlnaDevice device) async {
    final failure = saveFailure;
    return failure == null
        ? const Success<void>(null)
        : FailureResult<void>(failure);
  }

  @override
  Future<Result<void>> startDiscovery() async {
    startCalls++;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> stopDiscovery() async {
    stopCalls++;
    return const Success<void>(null);
  }

  void emit(Map<String, DiscoveredDlnaDevice> devices) => _devices.add(devices);

  @override
  Future<Result<void>> connect(
    DiscoveredDlnaDevice device, {
    required String mediaUrl,
    required String title,
  }) async => const Success<void>(null);

  @override
  Future<Result<DlnaPlaybackSnapshot>> readPlaybackStatus(
    DiscoveredDlnaDevice device,
  ) async {
    statusCalls++;
    concurrentStatusCalls++;
    maxConcurrentStatusCalls = maxConcurrentStatusCalls < concurrentStatusCalls
        ? concurrentStatusCalls
        : maxConcurrentStatusCalls;
    try {
      if (statusGates.isNotEmpty) return await statusGates.removeAt(0).future;
      return const Success<DlnaPlaybackSnapshot>(_playingSnapshot);
    } finally {
      concurrentStatusCalls--;
    }
  }

  @override
  Future<Result<void>> play(DiscoveredDlnaDevice device) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> pause(DiscoveredDlnaDevice device) async {
    final gate = pauseGate;
    if (gate != null) {
      pauseGate = null;
      return gate.future;
    }
    final failure = pauseFailure;
    return failure == null
        ? const Success<void>(null)
        : FailureResult<void>(failure);
  }

  @override
  Future<Result<void>> seek(
    DiscoveredDlnaDevice device,
    Duration position,
  ) async {
    seekTargets.add(position);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> setVolume(
    DiscoveredDlnaDevice device,
    double volume,
  ) async => const Success<void>(null);

  @override
  Future<Result<void>> stopPlayback(DiscoveredDlnaDevice device) async =>
      const Success<void>(null);

  @override
  Future<void> dispose() => _disposeFuture ??= _dispose();

  Future<void> _dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _devices.close();
  }
}
