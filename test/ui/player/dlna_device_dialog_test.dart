import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/dlna_device_repository.dart';
import 'package:selene/domain/models/dlna_device.dart';
import 'package:selene/ui/player/view_models/dlna_cast_view_model.dart';
import 'package:selene/ui/player/widgets/dlna_device_dialog.dart';
import 'package:selene/utils/result.dart';

void main() {
  late _FakeDlnaDeviceRepository repository;
  late DlnaCastViewModel castViewModel;

  setUp(() {
    repository = _FakeDlnaDeviceRepository();
    castViewModel = DlnaCastViewModel(repository: repository);
  });

  tearDown(() async {
    castViewModel.dispose();
    await repository.dispose();
  });

  testWidgets('最近设备独立复制展示且全部设备保持原发现顺序', (tester) async {
    final recentDevice = _device(
      endpoint: 'http://192.168.1.20:1400',
      name: '客厅电视',
    );
    final sameNameDevice = _device(
      endpoint: 'http://192.168.1.21:1400',
      name: '客厅电视',
    );
    final bedroomDevice = _device(
      endpoint: 'http://192.168.1.22:1400',
      name: '卧室电视',
    );

    await _pumpDialog(
      tester,
      castViewModel: castViewModel,
      recentDevice: _recent(recentDevice),
    );
    repository.emit(<String, DiscoveredDlnaDevice>{
      sameNameDevice.endpoint: sameNameDevice,
      bedroomDevice.endpoint: bedroomDevice,
      recentDevice.endpoint: recentDevice,
    });
    await tester.pump();

    expect(find.text('最近使用'), findsOneWidget);
    expect(find.text('全部设备'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('recent-device')),
        matching: find.text('客厅电视'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('客厅电视 ·'), findsNothing);

    final list = tester.widget<ListView>(find.byType(ListView));
    final delegate = list.childrenDelegate as SliverChildListDelegate;
    expect(delegate.children.map((child) => child.key).whereType<Key>(), <Key>[
      const ValueKey<String>('recent-device'),
      ValueKey<String>('device-${sameNameDevice.endpoint}'),
      ValueKey<String>('device-${bedroomDevice.endpoint}'),
      ValueKey<String>('device-${recentDevice.endpoint}'),
    ]);
  });

  testWidgets('历史设备未发现时保留不可点击卡片且其他设备照常选择', (tester) async {
    var connected = 0;
    final other = _device(endpoint: 'http://192.168.1.30:1400', name: '书房电视');

    await _pumpDialog(
      tester,
      castViewModel: castViewModel,
      recentDevice: const RecentDlnaDevice(
        endpoint: 'http://192.168.1.20:1400',
        friendlyName: '客厅电视',
        deviceType: 'renderer',
      ),
      onConnect: (_) async {
        connected++;
        return const Success<void>(null);
      },
    );
    repository.emit(<String, DiscoveredDlnaDevice>{other.endpoint: other});
    await tester.pump();

    expect(find.text('当前未发现'), findsOneWidget);
    await tester.tap(find.text('客厅电视'));
    await tester.pump();
    expect(connected, 0);

    await tester.tap(find.text('书房电视'));
    await tester.pump();
    expect(connected, 1);
  });

  testWidgets('连接完成前不报告成功，失败后保留设备列表和最近记录', (tester) async {
    final device = _device(endpoint: 'http://192.168.1.20:1400', name: '客厅电视');
    final gate = Completer<Result<void>>();
    DiscoveredDlnaDevice? startedDevice;

    await _pumpDialog(
      tester,
      castViewModel: castViewModel,
      recentDevice: _recent(device),
      onConnect: (_) => gate.future,
      onCastStarted: (value) => startedDevice = value,
    );
    repository.emit(<String, DiscoveredDlnaDevice>{device.endpoint: device});
    await tester.pump();

    await tester.tap(find.text('客厅电视').first);
    await tester.pump();
    expect(startedDevice, isNull);
    expect(find.text('正在投屏到 客厅电视...'), findsOneWidget);

    gate.complete(
      const FailureResult<void>(
        AppFailure(kind: FailureKind.network, message: '设备连接失败'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(startedDevice, isNull);
    expect(find.text('选择投屏设备'), findsOneWidget);
    expect(find.text('设备连接失败'), findsOneWidget);
  });

  testWidgets('当前设备按端点精确识别，同名的其他设备仍可选择', (tester) async {
    final current = _device(endpoint: 'http://192.168.1.20:1400', name: '客厅电视');
    final sameName = _device(
      endpoint: 'http://192.168.1.21:1400',
      name: '客厅电视',
    );
    DiscoveredDlnaDevice? connectedDevice;

    await _pumpDialog(
      tester,
      castViewModel: castViewModel,
      currentDevice: current,
      onConnect: (device) async {
        connectedDevice = device;
        return const Success<void>(null);
      },
    );
    repository.emit(<String, DiscoveredDlnaDevice>{
      current.endpoint: current,
      sameName.endpoint: sameName,
    });
    await tester.pump();

    expect(find.text('当前设备'), findsOneWidget);
    await tester.tap(
      find.byKey(ValueKey<String>('device-${sameName.endpoint}')),
    );
    await tester.pump();

    expect(connectedDevice, same(sameName));
  });
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  required DlnaCastViewModel castViewModel,
  RecentDlnaDevice? recentDevice,
  DiscoveredDlnaDevice? currentDevice,
  Future<Result<void>> Function(DiscoveredDlnaDevice device)? onConnect,
  ValueChanged<DiscoveredDlnaDevice>? onCastStarted,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => DLNADeviceDialog(
                castViewModel: castViewModel,
                recentDevice: recentDevice,
                currentDevice: currentDevice,
                onConnect: onConnect ?? (_) async => const Success<void>(null),
                onCastStarted: onCastStarted,
              ),
            ),
            child: const Text('打开设备'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('打开设备'));
  await tester.pumpAndSettle();
}

DiscoveredDlnaDevice _device({
  required String endpoint,
  required String name,
}) => DiscoveredDlnaDevice(
  id: endpoint,
  endpoint: endpoint,
  friendlyName: name,
  deviceType: 'urn:schemas-upnp-org:device:MediaRenderer:1',
  activeTime: DateTime.now(),
);

RecentDlnaDevice _recent(DiscoveredDlnaDevice device) =>
    device.toRecentDevice();

final class _FakeDlnaDeviceRepository implements DlnaDeviceRepository {
  final StreamController<Map<String, DiscoveredDlnaDevice>> _devices =
      StreamController<Map<String, DiscoveredDlnaDevice>>.broadcast(sync: true);
  bool _disposed = false;

  @override
  Stream<Map<String, DiscoveredDlnaDevice>> get devices => _devices.stream;

  @override
  Future<Result<void>> startDiscovery() async => const Success<void>(null);

  @override
  Future<Result<void>> stopDiscovery() async => const Success<void>(null);

  @override
  Future<Result<RecentDlnaDevice?>> loadRecent() async =>
      const Success<RecentDlnaDevice?>(null);

  @override
  Future<Result<void>> saveRecent(RecentDlnaDevice device) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> connect(
    DiscoveredDlnaDevice device, {
    required String mediaUrl,
    required String title,
  }) async => const Success<void>(null);

  @override
  Future<Result<DlnaPlaybackSnapshot>> readPlaybackStatus(
    DiscoveredDlnaDevice device,
  ) async => const Success<DlnaPlaybackSnapshot>(
    DlnaPlaybackSnapshot(
      position: Duration.zero,
      duration: Duration.zero,
      playing: false,
    ),
  );

  @override
  Future<Result<void>> play(DiscoveredDlnaDevice device) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> pause(DiscoveredDlnaDevice device) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> seek(
    DiscoveredDlnaDevice device,
    Duration position,
  ) async => const Success<void>(null);

  @override
  Future<Result<void>> setVolume(
    DiscoveredDlnaDevice device,
    double volume,
  ) async => const Success<void>(null);

  @override
  Future<Result<void>> stopPlayback(DiscoveredDlnaDevice device) async =>
      const Success<void>(null);

  void emit(Map<String, DiscoveredDlnaDevice> devices) => _devices.add(devices);

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _devices.close();
  }
}
