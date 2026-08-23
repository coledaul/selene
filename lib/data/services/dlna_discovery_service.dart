import 'dart:async';

import 'package:dlna_dart/dlna.dart';

abstract interface class DlnaDiscoveryService {
  Stream<Map<String, DLNADevice>> get devices;
  DLNADevice? findDevice(String id);
  Future<void> start();
  Future<void> stop();
  Future<void> dispose();
}

final class DefaultDlnaDiscoveryService implements DlnaDiscoveryService {
  final StreamController<Map<String, DLNADevice>> _devices =
      StreamController<Map<String, DLNADevice>>.broadcast();
  DLNAManager? _manager;
  StreamSubscription<Map<String, DLNADevice>>? _subscription;
  final Map<String, DLNADevice> _knownDevices = <String, DLNADevice>{};
  bool _disposed = false;

  @override
  Stream<Map<String, DLNADevice>> get devices => _devices.stream;

  @override
  DLNADevice? findDevice(String id) => _knownDevices[id];

  @override
  Future<void> start() async {
    if (_disposed) return;
    await stop();
    final manager = DLNAManager();
    _manager = manager;
    final deviceManager = await manager.start();
    if (_disposed || !identical(_manager, manager)) {
      manager.stop();
      return;
    }
    _subscription = deviceManager.devices.stream.listen(
      (value) {
        if (!_devices.isClosed) {
          _knownDevices.addAll(value);
          _devices.add(Map<String, DLNADevice>.unmodifiable(value));
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_devices.isClosed) _devices.addError(error, stackTrace);
      },
    );
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _manager?.stop();
    _manager = null;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stop();
    _knownDevices.clear();
    await _devices.close();
  }
}
