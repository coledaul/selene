import 'dart:async';

import 'package:dlna_dart/dlna.dart';
import 'package:dlna_dart/xmlParser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/services/dlna_playback_service.dart';
import 'package:selene/domain/models/dlna_device.dart';
import 'package:selene/utils/result.dart';

void main() {
  const service = DefaultDlnaPlaybackService();

  test('连接严格等待设置地址完成后再播放，并等待播放确认', () async {
    final device = _FakeDlnaDevice();
    final setUrlGate = Completer<String>();
    final playGate = Completer<String>();
    device.setUrlResult = setUrlGate.future;
    device.playResult = playGate.future;

    final connection = service.connect(
      device,
      mediaUrl: 'https://example.com/video.m3u8',
      title: '测试影片',
    );
    await Future<void>.delayed(Duration.zero);

    expect(device.calls, <String>['setUrl']);
    setUrlGate.complete('ok');
    await Future<void>.delayed(Duration.zero);
    expect(device.calls, <String>['setUrl', 'play']);

    var completed = false;
    unawaited(connection.then((_) => completed = true));
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);

    playGate.complete('ok');
    expect(await connection, isA<Success<void>>());
  });

  test('设备命令失败返回网络错误且不伪造成功', () async {
    final device = _FakeDlnaDevice()
      ..setUrlResult = Future<String>.error(StateError('offline'));

    final result = await service.connect(
      device,
      mediaUrl: 'https://example.com/video.m3u8',
      title: '测试影片',
    );

    expect(result, isA<FailureResult<void>>());
    expect(result.failureOrNull?.kind, FailureKind.network);
    expect(device.calls, <String>['setUrl']);
  });

  test('停止命令同样等待设备确认', () async {
    final device = _FakeDlnaDevice();
    final stopGate = Completer<String>();
    device.stopResult = stopGate.future;

    final stopping = service.stop(device);
    await Future<void>.delayed(Duration.zero);
    expect(device.calls, <String>['stop']);

    stopGate.complete('ok');
    expect(await stopping, isA<Success<void>>());
  });

  test('状态读取串行获取位置和传输状态并在 Service 解析', () async {
    final device = _FakeDlnaDevice();

    final result = await service.readStatus(device);

    expect(device.calls, <String>['position', 'transport']);
    expect(result, isA<Success<DlnaPlaybackSnapshot>>());
    expect(result.valueOrNull?.position, const Duration(seconds: 12));
    expect(result.valueOrNull?.duration, const Duration(minutes: 2));
    expect(result.valueOrNull?.playing, isTrue);
  });

  test('暂停、跳转和音量命令都等待确认并显式返回失败', () async {
    final device = _FakeDlnaDevice()
      ..pauseResult = Future<String>.error(StateError('offline'));

    final pause = await service.pause(device);
    final seek = await service.seek(
      device,
      const Duration(hours: 1, minutes: 2, seconds: 3),
    );
    final volume = await service.setVolume(device, 0.35);

    expect(pause, isA<FailureResult<void>>());
    expect(pause.failureOrNull?.message, '暂停投屏播放失败');
    expect(seek, isA<Success<void>>());
    expect(volume, isA<Success<void>>());
    expect(device.seekTargets, <String>['01:02:03']);
    expect(device.volumeTargets, <int>[35]);
  });
}

final class _FakeDlnaDevice extends DLNADevice {
  _FakeDlnaDevice()
    : super(
        DeviceInfo(
          'http://192.168.1.20:1400',
          'urn:schemas-upnp-org:device:MediaRenderer:1',
          '客厅电视',
          const <dynamic>[],
        ),
      );

  final List<String> calls = <String>[];
  Future<String> setUrlResult = Future<String>.value('ok');
  Future<String> playResult = Future<String>.value('ok');
  Future<String> stopResult = Future<String>.value('ok');
  Future<String> pauseResult = Future<String>.value('ok');
  Future<String> seekResult = Future<String>.value('ok');
  Future<String> volumeResult = Future<String>.value('ok');
  Future<String> positionResult = Future<String>.value(
    '<root><TrackDuration>00:02:00</TrackDuration>'
    '<RelTime>00:00:12</RelTime>'
    '<AbsTime>00:00:12</AbsTime>'
    '<TrackURI>https://example.com/video.mp4</TrackURI></root>',
  );
  Future<String> transportResult = Future<String>.value(
    '<root><CurrentTransportState>PLAYING</CurrentTransportState>'
    '<CurrentTransportStatus>OK</CurrentTransportStatus></root>',
  );
  final List<String> seekTargets = <String>[];
  final List<int> volumeTargets = <int>[];

  @override
  Future<String> setUrl(
    String url, {
    String title = '',
    PlayType type = VideoMime.any,
  }) {
    calls.add('setUrl');
    return setUrlResult;
  }

  @override
  Future<String> play() {
    calls.add('play');
    return playResult;
  }

  @override
  Future<String> stop() {
    calls.add('stop');
    return stopResult;
  }

  @override
  Future<String> position() {
    calls.add('position');
    return positionResult;
  }

  @override
  Future<String> getTransportInfo() {
    calls.add('transport');
    return transportResult;
  }

  @override
  Future<String> pause() {
    calls.add('pause');
    return pauseResult;
  }

  @override
  Future<String> seek(String target) {
    calls.add('seek');
    seekTargets.add(target);
    return seekResult;
  }

  @override
  Future<String> volume(int target) {
    calls.add('volume');
    volumeTargets.add(target);
    return volumeResult;
  }
}
