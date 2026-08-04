import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pip/pip.dart';
import '../../../utils/result.dart';
import '../video_playback_session.dart';
import 'mobile_player_controls.dart';
import 'pc_player_controls.dart';
import 'playback_status_overlay.dart';
import 'video_player_surface.dart';

/// 绑定页面生命周期的 media_kit 播放器视图。
class VideoPlayerWidget extends StatefulWidget {
  final VideoPlayerSurface surface;
  final String? url;
  final Map<String, String>? headers;
  final VoidCallback? onBackPressed;
  final Function(VideoPlayerWidgetController)? onControllerCreated;
  final VoidCallback? onReady;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onVideoCompleted;
  final VoidCallback? onPause;
  final bool isLastEpisode;
  final Function(dynamic)? onCastStarted;
  final Future<String?> Function()? onCastUrlRequested;
  final String? videoTitle;
  final String? overlayTitle;
  final int? currentEpisodeIndex;
  final int? totalEpisodes;
  final String? sourceName;
  final Function(bool isWebFullscreen)? onWebFullscreenChanged;
  final VoidCallback? onExitFullScreen;
  final bool live;
  final Function(bool isPipMode)? onPipModeChanged;
  final PlaybackMediaKind? mediaKind;
  final VideoPlaybackSession Function()? sessionFactory;

  const VideoPlayerWidget({
    super.key,
    this.surface = VideoPlayerSurface.mobile,
    this.url,
    this.headers,
    this.onBackPressed,
    this.onControllerCreated,
    this.onReady,
    this.onNextEpisode,
    this.onVideoCompleted,
    this.onPause,
    this.isLastEpisode = false,
    this.onCastStarted,
    this.onCastUrlRequested,
    this.videoTitle,
    this.overlayTitle,
    this.currentEpisodeIndex,
    this.totalEpisodes,
    this.sourceName,
    this.onWebFullscreenChanged,
    this.onExitFullScreen,
    this.live = false,
    this.onPipModeChanged,
    this.mediaKind,
    this.sessionFactory,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class VideoPlayerWidgetController {
  VideoPlayerWidgetController._({
    required VideoPlaybackSession session,
    required VoidCallback exitWebFullscreen,
    required bool Function() isPipMode,
  }) : _session = session,
       _exitWebFullscreen = exitWebFullscreen,
       _isPipMode = isPipMode;

  final VideoPlaybackSession _session;
  final VoidCallback _exitWebFullscreen;
  final bool Function() _isPipMode;

  Future<AppFailure?> updateDataSource(
    PlaybackMediaSource media, {
    Duration? startAt,
    Map<String, String>? headers,
  }) async {
    await _session.open(
      media.url,
      kind: media.kind,
      startAt: startAt,
      headers: headers,
    );
    return _session.state.failure;
  }

  Future<void> seekTo(Duration position) async {
    await _session.seek(position);
  }

  Duration? get currentPosition => _session.state.position;

  Duration? get duration => _session.state.duration;

  bool get isPlaying => _session.state.playing;

  Future<void> pause() async {
    await _session.pause();
  }

  Future<void> play() async {
    await _session.play();
  }

  void addProgressListener(VoidCallback listener) {
    _session.addProgressListener(listener);
  }

  void removeProgressListener(VoidCallback listener) {
    _session.removeProgressListener(listener);
  }

  Future<void> setSpeed(double speed) async {
    await _session.setRate(speed);
  }

  double get playbackSpeed => _session.playbackRate;

  Future<void> setVolume(double volume) async {
    await _session.setVolume(volume);
  }

  double? get volume => _session.volume;

  void exitWebFullscreen() {
    _exitWebFullscreen();
  }

  bool get isPipMode => _isPipMode();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with WidgetsBindingObserver {
  late final VideoPlaybackSession _session;
  late VideoPlaybackState _lastPlaybackState;
  VoidCallback? _exitWebFullscreenCallback;
  final Pip _pip = Pip();
  bool _isPipMode = false;

  PlaybackMediaKind get _mediaKind =>
      widget.mediaKind ??
      (widget.live ? PlaybackMediaKind.live : PlaybackMediaKind.networkVod);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session = widget.sessionFactory?.call() ?? VideoPlaybackSession();
    _lastPlaybackState = _session.state;
    _session.addListener(_handleSessionChanged);
    _setupPip();
    _registerPipObserver();
    widget.onControllerCreated?.call(
      VideoPlayerWidgetController._(
        session: _session,
        exitWebFullscreen: _exitWebFullscreen,
        isPipMode: () => _isPipMode,
      ),
    );
    final url = widget.url;
    if (url != null) {
      unawaited(
        _session.open(
          url,
          kind: _mediaKind,
          headers: widget.headers ?? const <String, String>{},
        ),
      );
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sourceChanged =
        widget.url != oldWidget.url ||
        !mapEquals(widget.headers, oldWidget.headers) ||
        widget.live != oldWidget.live ||
        widget.mediaKind != oldWidget.mediaKind;
    final url = widget.url;
    if (sourceChanged && url != null) {
      unawaited(
        _session.open(
          url,
          kind: _mediaKind,
          headers: widget.headers ?? const <String, String>{},
        ),
      );
    }
  }

  void _handleSessionChanged() {
    if (!mounted) return;
    final next = _session.state;
    final becameReady = !_lastPlaybackState.ready && next.ready;
    final becameCompleted =
        !_lastPlaybackState.completed && next.completed && !widget.live;
    final playingChanged = _lastPlaybackState.playing != next.playing;
    _lastPlaybackState = next;
    if (playingChanged) {
      _configurePipForPlayback(next.playing);
    }
    setState(() {});
    if (becameReady) widget.onReady?.call();
    if (becameCompleted) widget.onVideoCompleted?.call();
  }

  void _configurePipForPlayback(bool playing) {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    _pip.setup(
      PipOptions(
        autoEnterEnabled: playing,
        aspectRatioX: 16,
        aspectRatioY: 9,
        preferredContentWidth: 480,
        preferredContentHeight: 270,
        controlStyle: 2,
      ),
    );
  }

  void _exitWebFullscreen() {
    _exitWebFullscreenCallback?.call();
  }

  void _setupPip() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    _pip.setup(
      const PipOptions(
        autoEnterEnabled: true,
        aspectRatioX: 16,
        aspectRatioY: 9,
        preferredContentWidth: 480,
        preferredContentHeight: 270,
        controlStyle: 2,
      ),
    );
  }

  void _registerPipObserver() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    _pip.registerStateChangedObserver(
      PipStateChangedObserver(
        onPipStateChanged: (state, error) {
          if (!mounted) return;
          switch (state) {
            case PipState.pipStateStarted:
              debugPrint('PiP started successfully');
              if (mounted) {
                setState(() => _isPipMode = true);
                widget.onPipModeChanged?.call(true);
              }
              break;
            case PipState.pipStateStopped:
              debugPrint('PiP stopped');
              if (mounted) {
                setState(() {
                  _isPipMode = false;
                });
                widget.onPipModeChanged?.call(false);
              }
              break;
            case PipState.pipStateFailed:
              debugPrint('PiP failed: $error');
              if (mounted) {
                setState(() => _isPipMode = false);
                widget.onPipModeChanged?.call(false);
              }
              break;
          }
        },
      ),
    );
  }

  Future<void> _enterPipMode() async {
    debugPrint('_enterPipMode');
    try {
      var support = await _pip.isSupported();
      if (!support) {
        debugPrint('Device does not support PiP!');
        return;
      }
      await _session.play();
      await _pip.start();
    } catch (e) {
      debugPrint('Failed to enter PiP mode: $e');
      _setupPip();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.removeListener(_handleSessionChanged);
    if (Platform.isAndroid || Platform.isIOS) {
      _pip.unregisterStateChangedObserver();
      _pip.dispose();
    }
    unawaited(_session.disposeSession());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = _session.state;
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Video(
            controller: _session.videoController,
            controls: (state) {
              return widget.surface == VideoPlayerSurface.desktop
                  ? PCPlayerControls(
                      state: state,
                      onBackPressed: widget.onBackPressed,
                      onNextEpisode: widget.onNextEpisode,
                      onPause: widget.onPause,
                      canCast:
                          widget.onCastUrlRequested != null ||
                          playbackState.mediaKind !=
                              PlaybackMediaKind.localFile,
                      onCastUrlRequested:
                          widget.onCastUrlRequested ?? _currentMediaUrl,
                      isLastEpisode: widget.isLastEpisode,
                      isLoadingVideo: playbackState.opening,
                      onCastStarted: widget.onCastStarted,
                      videoTitle: widget.videoTitle,
                      overlayTitle: widget.overlayTitle,
                      currentEpisodeIndex: widget.currentEpisodeIndex,
                      totalEpisodes: widget.totalEpisodes,
                      sourceName: widget.sourceName,
                      onWebFullscreenChanged: widget.onWebFullscreenChanged,
                      onExitWebFullscreenCallbackReady: (callback) {
                        _exitWebFullscreenCallback = callback;
                      },
                      onExitFullScreen: widget.onExitFullScreen,
                      live: widget.live,
                      onPlayRequested: _session.play,
                      onPauseRequested: _session.pause,
                      onSetSpeed: _session.setRate,
                      onSetVolume: _session.setVolume,
                      playbackState: playbackState,
                      onSeekRequested: _session.seek,
                    )
                  : MobilePlayerControls(
                      state: state,
                      onControlsVisibilityChanged: (_) {},
                      onBackPressed: widget.onBackPressed,
                      onFullscreenChange: (_) {},
                      onNextEpisode: widget.onNextEpisode,
                      onPause: widget.onPause,
                      canCast:
                          widget.onCastUrlRequested != null ||
                          playbackState.mediaKind !=
                              PlaybackMediaKind.localFile,
                      onCastUrlRequested:
                          widget.onCastUrlRequested ?? _currentMediaUrl,
                      isLastEpisode: widget.isLastEpisode,
                      isLoadingVideo: playbackState.opening,
                      onCastStarted: widget.onCastStarted,
                      videoTitle: widget.videoTitle,
                      overlayTitle: widget.overlayTitle,
                      currentEpisodeIndex: widget.currentEpisodeIndex,
                      totalEpisodes: widget.totalEpisodes,
                      sourceName: widget.sourceName,
                      onExitFullScreen: widget.onExitFullScreen,
                      live: widget.live,
                      onPlayRequested: _session.play,
                      onPauseRequested: _session.pause,
                      onSetSpeed: _session.setRate,
                      onEnterPipMode: _enterPipMode,
                      isPipMode: _isPipMode,
                      playbackState: playbackState,
                      onSeekRequested: _session.seek,
                    );
            },
          ),
          if (playbackState.buffering && !playbackState.opening)
            const IgnorePointer(
              child: Center(
                child: SizedBox.square(
                  dimension: 32,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          PlaybackStatusOverlay(
            state: playbackState,
            live: widget.live,
            isLastEpisode: widget.isLastEpisode,
            onRetry: _session.retryCurrent,
            onDismiss: _session.clearProblem,
            onReplay: _session.replay,
            onNextEpisode: widget.onNextEpisode,
            onBackPressed: widget.onBackPressed,
          ),
        ],
      ),
    );
  }

  Future<String?> _currentMediaUrl() async => _session.currentUrl;
}
