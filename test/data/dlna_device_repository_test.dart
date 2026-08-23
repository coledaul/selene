import 'dart:async';

import 'package:dlna_dart/dlna.dart';
import 'package:dlna_dart/xmlParser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/dlna_device_repository.dart';
import 'package:selene/data/services/dlna_device_preferences_service.dart';
import 'package:selene/data/services/dlna_discovery_service.dart';
import 'package:selene/data/services/dlna_playback_service.dart';
import 'package:selene/domain/models/dlna_device.dart';
import 'package:selene/utils/result.dart';

void main() {
  const recent = RecentDlnaDevice(
    endpoint: 'http://192.168.1.20:1400',
    friendlyName: '客厅电视',
    deviceType: 'urn:schemas-upnp-org:device:MediaRenderer:1',
  );

  test('最近设备按完整身份读取和保存', () async {
    final service = _FakeDlnaDevicePreferencesService(recent: recent);
    final repository = _repository(service);
    addTearDown(repository.dispose);

    final loaded = await repository.loadRecent();
    expect(loaded.valueOrNull, recent);

    const next = RecentDlnaDevice(
      endpoint: 'http://192.168.1.21:1400/',
      friendlyName: '卧室电视',
      deviceType: 'renderer',
    );
    final saved = await repository.saveRecent(next);

    expect(saved, isA<Success<void>>());
    expect(service.saved, next);
  });

  test('存储异常映射为明确失败且不伪造成功', () async {
    final repository = _repository(_ThrowingDlnaDevicePreferencesService());
    addTearDown(repository.dispose);

    final loaded = await repository.loadRecent();
    final saved = await repository.saveRecent(recent);

    expect(loaded.failureOrNull?.kind, FailureKind.storage);
    expect(loaded.failureOrNull?.message, '无法读取最近投屏设备');
    expect(saved.failureOrNull?.kind, FailureKind.storage);
    expect(saved.failureOrNull?.message, '无法保存最近投屏设备');
  });

  test('设备端点只做稳定的尾斜杠归一化，不按名称模糊匹配', () {
    expect(recent.matchesEndpoint('http://192.168.1.20:1400/'), isTrue);
    expect(recent.matchesEndpoint('http://192.168.1.21:1400'), isFalse);
  });

  test('Repository 向 UI 映射领域快照并用稳定 id 解析运行时设备', () async {
    final discovery = _FakeDlnaDiscoveryService();
    final playback = _FakeDlnaPlaybackService();
    final repository = DefaultDlnaDeviceRepository(
      preferencesService: _FakeDlnaDevicePreferencesService(),
      discoveryService: discovery,
      playbackService: playback,
    );
    addTearDown(repository.dispose);
    final target = _device();
    final snapshotFuture = repository.devices.first;

    discovery.emit(<String, DLNADevice>{'living-room': target});
    final snapshot = (await snapshotFuture).values.single;
    final result = await repository.connect(
      snapshot,
      mediaUrl: 'https://example.com/video.mp4',
      title: '测试影片',
    );

    expect(snapshot.id, 'living-room');
    expect(snapshot.endpoint, target.info.URLBase);
    expect(snapshot.friendlyName, target.info.friendlyName);
    expect(result, isA<Success<void>>());
    expect(playback.connectedDevice, same(target));
  });
}

DefaultDlnaDeviceRepository _repository(
  DlnaDevicePreferencesService preferencesService,
) => DefaultDlnaDeviceRepository(
  preferencesService: preferencesService,
  discoveryService: DefaultDlnaDiscoveryService(),
  playbackService: const DefaultDlnaPlaybackService(),
);

final class _FakeDlnaDevicePreferencesService
    implements DlnaDevicePreferencesService {
  _FakeDlnaDevicePreferencesService({this.recent});

  RecentDlnaDevice? recent;
  RecentDlnaDevice? saved;

  @override
  Future<RecentDlnaDevice?> loadRecent() async => recent;

  @override
  Future<void> saveRecent(RecentDlnaDevice device) async {
    saved = device;
  }
}

final class _ThrowingDlnaDevicePreferencesService
    implements DlnaDevicePreferencesService {
  @override
  Future<RecentDlnaDevice?> loadRecent() => Future.error(StateError('read'));

  @override
  Future<void> saveRecent(RecentDlnaDevice device) =>
      Future.error(StateError('write'));
}

DLNADevice _device() => DLNADevice(
  DeviceInfo(
    'http://192.168.1.20:1400',
    'urn:schemas-upnp-org:device:MediaRenderer:1',
    '客厅电视',
    const <dynamic>[],
  ),
);

final class _FakeDlnaDiscoveryService implements DlnaDiscoveryService {
  final StreamController<Map<String, DLNADevice>> _devices =
      StreamController<Map<String, DLNADevice>>.broadcast(sync: true);
  Map<String, DLNADevice> _current = const <String, DLNADevice>{};

  @override
  Stream<Map<String, DLNADevice>> get devices => _devices.stream;

  void emit(Map<String, DLNADevice> devices) {
    _current = Map<String, DLNADevice>.of(devices);
    _devices.add(_current);
  }

  @override
  DLNADevice? findDevice(String id) => _current[id];

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() => _devices.close();
}

final class _FakeDlnaPlaybackService implements DlnaPlaybackService {
  DLNADevice? connectedDevice;

  @override
  Future<Result<void>> connect(
    DLNADevice device, {
    required String mediaUrl,
    required String title,
  }) async {
    connectedDevice = device;
    return const Success<void>(null);
  }

  @override
  Future<Result<DlnaPlaybackSnapshot>> readStatus(DLNADevice device) async =>
      const Success<DlnaPlaybackSnapshot>(
        DlnaPlaybackSnapshot(
          position: Duration.zero,
          duration: Duration.zero,
          playing: false,
        ),
      );

  @override
  Future<Result<void>> play(DLNADevice device) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> pause(DLNADevice device) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> seek(DLNADevice device, Duration position) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> setVolume(DLNADevice device, double volume) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> stop(DLNADevice device) async =>
      const Success<void>(null);
}
