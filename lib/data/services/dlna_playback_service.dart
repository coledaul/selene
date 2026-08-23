import 'package:dlna_dart/dlna.dart';
import 'package:dlna_dart/xmlParser.dart';

import '../../domain/models/dlna_device.dart';
import '../../utils/result.dart';

abstract interface class DlnaPlaybackService {
  Future<Result<void>> connect(
    DLNADevice device, {
    required String mediaUrl,
    required String title,
  });

  Future<Result<DlnaPlaybackSnapshot>> readStatus(DLNADevice device);
  Future<Result<void>> play(DLNADevice device);
  Future<Result<void>> pause(DLNADevice device);
  Future<Result<void>> seek(DLNADevice device, Duration position);
  Future<Result<void>> setVolume(DLNADevice device, double volume);
  Future<Result<void>> stop(DLNADevice device);
}

final class DefaultDlnaPlaybackService implements DlnaPlaybackService {
  const DefaultDlnaPlaybackService();

  @override
  Future<Result<void>> connect(
    DLNADevice device, {
    required String mediaUrl,
    required String title,
  }) => _command('投屏连接失败，请检查设备后重试', () async {
    await device.setUrl(mediaUrl, title: title);
    await device.play();
  });

  @override
  Future<Result<DlnaPlaybackSnapshot>> readStatus(DLNADevice device) =>
      _guard('读取投屏状态失败', () async {
        final position = PositionParser(await device.position());
        final transport = TransportInfoParser(await device.getTransportInfo());
        return DlnaPlaybackSnapshot(
          position: Duration(seconds: position.RelTimeInt),
          duration: Duration(seconds: position.TrackDurationInt),
          playing: transport.CurrentTransportState == 'PLAYING',
        );
      });

  @override
  Future<Result<void>> play(DLNADevice device) =>
      _command('继续投屏播放失败', () async {
        await device.play();
      });

  @override
  Future<Result<void>> pause(DLNADevice device) =>
      _command('暂停投屏播放失败', () async {
        await device.pause();
      });

  @override
  Future<Result<void>> seek(DLNADevice device, Duration position) =>
      _command('投屏跳转失败', () async {
        await device.seek(_formatPosition(position));
      });

  @override
  Future<Result<void>> setVolume(DLNADevice device, double volume) =>
      _command('投屏音量设置失败', () async {
        await device.volume((volume.clamp(0.0, 1.0) * 100).round());
      });

  @override
  Future<Result<void>> stop(DLNADevice device) => _command('停止投屏失败', () async {
    await device.stop();
  });

  Future<Result<void>> _command(
    String message,
    Future<void> Function() action,
  ) async {
    final result = await _guard<void>(message, action);
    if (result.isFailure) return FailureResult<void>(result.failureOrNull!);
    return const Success<void>(null);
  }

  Future<Result<T>> _guard<T>(
    String message,
    Future<T> Function() action,
  ) async {
    try {
      return Success<T>(await action());
    } catch (error, stackTrace) {
      return FailureResult<T>(
        AppFailure(
          kind: FailureKind.network,
          message: message,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}

String _formatPosition(Duration position) {
  if (position.isNegative) position = Duration.zero;
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(position.inHours)}:'
      '${twoDigits(position.inMinutes.remainder(60))}:'
      '${twoDigits(position.inSeconds.remainder(60))}';
}
