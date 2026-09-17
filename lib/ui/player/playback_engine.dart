import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'native_playback_bridge.dart';
import 'playback_first_frame.dart';
import 'video_output_readiness.dart';

abstract interface class PlaybackEngine {
  VideoController get videoController;

  Stream<Duration> get positions;
  Stream<Duration> get durations;
  Stream<bool> get playingChanges;
  Stream<bool> get bufferingChanges;
  Stream<bool> get completedChanges;
  Stream<String> get errors;

  Duration get position;
  Duration get duration;
  bool get playing;
  bool get buffering;
  double get rate;
  double get volume;
  bool get supportsNativeCacheProperties;

  Future<void> stop();
  Future<void> waitUntilFirstFrameRendered();
  Future<void> open(
    String url, {
    required Map<String, String> headers,
    Duration? startAt,
  });
  Future<void> setProperty(String property, String value);
  Future<void> observeCacheState(Future<void> Function(String value) listener);
  Future<String?> readCacheState();
  Future<void> unobserveCacheState();
  Future<void> seek(Duration position);
  Future<void> play();
  Future<void> pause();
  Future<void> setRate(double rate);
  Future<void> setVolume(double volume);
  Future<void> dispose();
}

final class MediaKitPlaybackEngine implements PlaybackEngine {
  MediaKitPlaybackEngine()
    : _player = Player(
        configuration: const PlayerConfiguration(bufferSize: 32 * 1024 * 1024),
      ) {
    _videoController = VideoController(_player);
    _nativeBridge = NativePlaybackBridge(_player);
    _firstFrame = PlaybackFirstFrame(
      waitForOutput: () => _videoController.waitUntilFirstFrameRendered,
      isOutputReady: _isAndroid
          ? _nativeBridge.hasRenderedVideoFrame
          : _hasUsableVideoOutput,
      waitForPresentation: () => WidgetsBinding.instance.endOfFrame,
    );
  }

  final Player _player;
  late final VideoController _videoController;
  late final NativePlaybackBridge _nativeBridge;
  late final PlaybackFirstFrame _firstFrame;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> _hasUsableVideoOutput() async {
    // Web 使用 HTML video，不套用原生 Texture 的占位尺寸约定。
    if (kIsWeb) return true;
    return isVideoOutputUsable(
      textureId: _videoController.id.value,
      textureRect: _videoController.rect.value,
      videoWidth: _player.state.width,
      videoHeight: _player.state.height,
    );
  }

  @override
  VideoController get videoController => _videoController;

  @override
  Stream<Duration> get positions => _player.stream.position;

  @override
  Stream<Duration> get durations => _player.stream.duration;

  @override
  Stream<bool> get playingChanges => _player.stream.playing;

  @override
  Stream<bool> get bufferingChanges => _player.stream.buffering;

  @override
  Stream<bool> get completedChanges => _player.stream.completed;

  @override
  Stream<String> get errors => _player.stream.error;

  @override
  Duration get position => _player.state.position;

  @override
  Duration get duration => _player.state.duration;

  @override
  bool get playing => _player.state.playing;

  @override
  bool get buffering => _player.state.buffering;

  @override
  double get rate => _player.state.rate;

  @override
  double get volume => _player.state.volume;

  @override
  bool get supportsNativeCacheProperties => _nativeBridge.supported;

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> waitUntilFirstFrameRendered() => _firstFrame.wait();

  @override
  Future<void> open(
    String url, {
    required Map<String, String> headers,
    Duration? startAt,
  }) async {
    if (_isAndroid) {
      // 保留 mpv 启动/seek 时等待 VO 输出首帧的保证。
      await _nativeBridge.setProperty('video-latency-hacks', 'no');
    }
    await _player.open(
      Media(url, start: startAt, httpHeaders: headers),
      play: true,
    );
  }

  @override
  Future<void> setProperty(String property, String value) =>
      _nativeBridge.setProperty(property, value);

  @override
  Future<void> observeCacheState(
    Future<void> Function(String value) listener,
  ) => _nativeBridge.observeCacheState(listener);

  @override
  Future<String?> readCacheState() => _nativeBridge.readCacheState();

  @override
  Future<void> unobserveCacheState() => _nativeBridge.unobserveCacheState();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> setRate(double rate) => _player.setRate(rate);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> dispose() {
    _firstFrame.dispose();
    return _player.dispose();
  }
}

typedef PlaybackDiagnostic = void Function(String event, Object error);
