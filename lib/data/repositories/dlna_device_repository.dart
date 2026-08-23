import 'package:dlna_dart/dlna.dart';

import '../../domain/models/dlna_device.dart';
import '../../utils/result.dart';
import '../services/dlna_device_preferences_service.dart';
import '../services/dlna_discovery_service.dart';
import '../services/dlna_playback_service.dart';

abstract interface class DlnaDeviceRepository {
  Stream<Map<String, DiscoveredDlnaDevice>> get devices;
  Future<Result<RecentDlnaDevice?>> loadRecent();
  Future<Result<void>> saveRecent(RecentDlnaDevice device);
  Future<Result<void>> startDiscovery();
  Future<Result<void>> stopDiscovery();
  Future<Result<void>> connect(
    DiscoveredDlnaDevice device, {
    required String mediaUrl,
    required String title,
  });
  Future<Result<DlnaPlaybackSnapshot>> readPlaybackStatus(
    DiscoveredDlnaDevice device,
  );
  Future<Result<void>> play(DiscoveredDlnaDevice device);
  Future<Result<void>> pause(DiscoveredDlnaDevice device);
  Future<Result<void>> seek(DiscoveredDlnaDevice device, Duration position);
  Future<Result<void>> setVolume(DiscoveredDlnaDevice device, double volume);
  Future<Result<void>> stopPlayback(DiscoveredDlnaDevice device);
  Future<void> dispose();
}

final class DefaultDlnaDeviceRepository implements DlnaDeviceRepository {
  const DefaultDlnaDeviceRepository({
    required DlnaDevicePreferencesService preferencesService,
    required DlnaDiscoveryService discoveryService,
    required DlnaPlaybackService playbackService,
  }) : _preferencesService = preferencesService,
       _discoveryService = discoveryService,
       _playbackService = playbackService;

  final DlnaDevicePreferencesService _preferencesService;
  final DlnaDiscoveryService _discoveryService;
  final DlnaPlaybackService _playbackService;

  @override
  Stream<Map<String, DiscoveredDlnaDevice>> get devices =>
      _discoveryService.devices.map((devices) {
        return Map<String, DiscoveredDlnaDevice>.unmodifiable(
          devices.map((id, device) {
            return MapEntry<String, DiscoveredDlnaDevice>(
              id,
              DiscoveredDlnaDevice(
                id: id,
                endpoint: device.info.URLBase,
                friendlyName: device.info.friendlyName,
                deviceType: device.info.deviceType,
                activeTime: device.activeTime,
              ),
            );
          }),
        );
      });

  @override
  Future<Result<RecentDlnaDevice?>> loadRecent() =>
      _guard('无法读取最近投屏设备', FailureKind.storage, _preferencesService.loadRecent);

  @override
  Future<Result<void>> saveRecent(RecentDlnaDevice device) => _guard(
    '无法保存最近投屏设备',
    FailureKind.storage,
    () => _preferencesService.saveRecent(device),
  );

  @override
  Future<Result<void>> startDiscovery() =>
      _guard('扫描投屏设备失败', FailureKind.network, _discoveryService.start);

  @override
  Future<Result<void>> stopDiscovery() =>
      _guard('停止扫描投屏设备失败', FailureKind.network, _discoveryService.stop);

  @override
  Future<Result<void>> connect(
    DiscoveredDlnaDevice device, {
    required String mediaUrl,
    required String title,
  }) => _withDevice(
    device,
    (target) =>
        _playbackService.connect(target, mediaUrl: mediaUrl, title: title),
  );

  @override
  Future<Result<DlnaPlaybackSnapshot>> readPlaybackStatus(
    DiscoveredDlnaDevice device,
  ) => _withDevice(device, _playbackService.readStatus);

  @override
  Future<Result<void>> play(DiscoveredDlnaDevice device) =>
      _withDevice(device, _playbackService.play);

  @override
  Future<Result<void>> pause(DiscoveredDlnaDevice device) =>
      _withDevice(device, _playbackService.pause);

  @override
  Future<Result<void>> seek(DiscoveredDlnaDevice device, Duration position) =>
      _withDevice(device, (target) => _playbackService.seek(target, position));

  @override
  Future<Result<void>> setVolume(DiscoveredDlnaDevice device, double volume) =>
      _withDevice(
        device,
        (target) => _playbackService.setVolume(target, volume),
      );

  @override
  Future<Result<void>> stopPlayback(DiscoveredDlnaDevice device) =>
      _withDevice(device, _playbackService.stop);

  @override
  Future<void> dispose() => _discoveryService.dispose();

  Future<Result<T>> _withDevice<T>(
    DiscoveredDlnaDevice device,
    Future<Result<T>> Function(DLNADevice target) action,
  ) {
    final target = _discoveryService.findDevice(device.id);
    if (target == null) {
      return Future<Result<T>>.value(
        FailureResult<T>(
          AppFailure(kind: FailureKind.network, message: '投屏设备已离线，请重新选择'),
        ),
      );
    }
    return action(target);
  }

  Future<Result<T>> _guard<T>(
    String message,
    FailureKind kind,
    Future<T> Function() action,
  ) async {
    try {
      return Success<T>(await action());
    } catch (error, stackTrace) {
      return FailureResult<T>(
        AppFailure(
          kind: kind,
          message: message,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
