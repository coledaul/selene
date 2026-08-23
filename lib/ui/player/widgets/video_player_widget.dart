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
  final ValueChanged<AppFailure>? onFailure;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onVideoCompleted;
  final VoidCallback? onPause;
  final bool isLastEpisode;
  final Future<void> Function()? onCastRequested;
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
    this.onFailure,
    this.onNextEpisode,
    this.onVideoCompleted,
    this.onPause,
    this.isLastEpisode = false,
    this.onCastRequested,
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
    required _VideoPlayerWidgetState owner,
    required VoidCallback exitWebFullscreen,
    required bool Function() isPipMode,
  }) : _owner = owner,
       _exitWebFullscreen = exitWebFullscreen,
       _isPipMode = isPipMode;

  final _VideoPlayerWidgetState _owner;
  final VoidCallback _exitWebFullscreen;
  final bool Function() _isPipMode;

  Future<void> updateDataSource(
    PlaybackMediaSource media, {
    Duration? startAt,
    Map<String, String>? headers,
  }) => _owner._replaceMedia(media, startAt: startAt, headers: headers);

  Future<void> seekTo(Duration position) async {
    await _owner._session.seek(position);
  }

  Duration? get currentPosition => _owner._session.state.position;

  Duration? get duration => _owner._session.state.duration;

  bool get isPlaying => _owner._session.state.playing;

  Future<void> pause() async {
    await _owner._session.pause();
  }

  Future<void> play() async {
    await _owner._session.play();
  }

  void addProgressListener(VoidCallback listener) {
    _owner._addProgressListener(listener);
  }

  void removeProgressListener(VoidCallback listener) {
    _owner._removeProgressListener(listener);
  }

  Future<void> setSpeed(double speed) async {
    await _owner._session.setRate(speed);
  }

  double get playbackSpeed => _owner._session.playbackRate;

  Future<void> setVolume(double volume) async {
    await _owner._session.setVolume(volume);
  }

  double? get volume => _owner._session.volume;

  void exitWebFullscreen() {
    _exitWebFullscreen();
  }

  bool get isPipMode => _isPipMode();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with WidgetsBindingObserver {
  late VideoPlaybackSession _session;
  late VideoPlaybackState _lastPlaybackState;
  final Set<VoidCallback> _progressListeners = <VoidCallback>{};
  Future<void> _sourceQueue = Future<void>.value();
  int _sourceGeneration = 0;
  PlaybackMediaSource? _currentMedia;
  Map<String, String> _currentHeaders = const <String, String>{};
  Duration? _currentStartAt;
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
    _session = _createSession();
    _lastPlaybackState = _session.state;
    _session.addListener(_handleSessionChanged);
    _setupPip();
    _registerPipObserver();
    widget.onControllerCreated?.call(
      VideoPlayerWidgetController._(
        owner: this,
        exitWebFullscreen: _exitWebFullscreen,
        isPipMode: () => _isPipMode,
      ),
    );
    final url = widget.url;
    if (url != null) {
      _currentMedia = PlaybackMediaSource(url: url, kind: _mediaKind);
      _currentHeaders = Map<String, String>.unmodifiable(
        widget.headers ?? const <String, String>{},
      );
      unawaited(_session.open(url, kind: _mediaKind, headers: _currentHeaders));
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
        _replaceMedia(
          PlaybackMediaSource(url: url, kind: _mediaKind),
          headers: widget.headers,
        ),
      );
    }
  }

  VideoPlaybackSession _createSession() =>
      widget.sessionFactory?.call() ?? VideoPlaybackSession();

  Future<void> _replaceMedia(
    PlaybackMediaSource media, {
    Duration? startAt,
    Map<String, String>? headers,
  }) {
    _currentMedia = media;
    _currentStartAt = startAt;
    _currentHeaders = Map<String, String>.unmodifiable(
      headers ?? const <String, String>{},
    );
    final generation = ++_sourceGeneration;
    final previous = _sourceQueue.catchError((Object _, StackTrace _) {});
    final operation = previous.then<void>((_) async {
      if (!_isActiveSource(generation)) return;
      final oldSession = _session;
      final rate = oldSession.playbackRate;
      final volume = oldSession.volume;
      oldSession.removeListener(_handleSessionChanged);
      for (final listener in _progressListeners) {
        oldSession.removeProgressListener(listener);
      }
      await oldSession.disposeSession();
      if (!_isActiveSource(generation)) return;

      final nextSession = _createSession();
      _session = nextSession;
      _lastPlaybackState = nextSession.state;
      nextSession.addListener(_handleSessionChanged);
      for (final listener in _progressListeners) {
        nextSession.addProgressListener(listener);
      }
      final rateOperation = nextSession.setRate(rate);
      final volumeOperation = nextSession.setVolume(volume);
      final openOperation = nextSession.open(
        media.url,
        kind: media.kind,
        startAt: startAt,
        headers: _currentHeaders,
      );
      if (mounted) setState(() {});
      await Future.wait(<Future<void>>[
        rateOperation,
        volumeOperation,
        openOperation,
      ]);
    });
    _sourceQueue = operation;
    return operation;
  }

  Future<void> _retryCurrentMedia() {
    final media = _currentMedia;
    if (media == null) return Future<void>.value();
    final position = _session.state.position;
    final startAt = position > Duration.zero ? position : _currentStartAt;
    return _replaceMedia(media, startAt: startAt, headers: _currentHeaders);
  }

  bool _isActiveSource(int generation) =>
      mounted && generation == _sourceGeneration;

  void _addProgressListener(VoidCallback listener) {
    if (_progressListeners.add(listener)) {
      _session.addProgressListener(listener);
    }
  }

  void _removeProgressListener(VoidCallback listener) {
    if (_progressListeners.remove(listener)) {
      _session.removeProgressListener(listener);
    }
  }

  void _handleSessionChanged() {
    if (!mounted) return;
    final next = _session.state;
    final becameReady = !_lastPlaybackState.ready && next.ready;
    final becameFailed =
        _lastPlaybackState.failure == null && next.failure != null;
    final becameCompleted =
        !_lastPlaybackState.completed && next.completed && !widget.live;
    final playingChanged = _lastPlaybackState.playing != next.playing;
    _lastPlaybackState = next;
    if (playingChanged) {
      _configurePipForPlayback(next.playing);
    }
    setState(() {});
    if (becameReady) widget.onReady?.call();
    if (becameFailed) widget.onFailure?.call(next.failure!);
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
    _sourceGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    _session.removeListener(_handleSessionChanged);
    for (final listener in _progressListeners) {
      _session.removeProgressListener(listener);
    }
    if (Platform.isAndroid || Platform.isIOS) {
      _pip.unregisterStateChangedObserver();
      _pip.dispose();
    }
    final queued = _sourceQueue.catchError((Object _, StackTrace _) {});
    unawaited(queued.then((_) => _session.disposeSession()));
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
                      canCast: widget.onCastRequested != null,
                      onCastRequested: _requestCast,
                      isLastEpisode: widget.isLastEpisode,
                      isLoadingVideo: playbackState.opening,
                      overlayTitle: widget.overlayTitle,
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
                      canCast: widget.onCastRequested != null,
                      onCastRequested: _requestCast,
                      isLastEpisode: widget.isLastEpisode,
                      isLoadingVideo: playbackState.opening,
                      overlayTitle: widget.overlayTitle,
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
            onRetry: _retryCurrentMedia,
            onDismiss: _session.clearProblem,
            onReplay: _session.replay,
            onNextEpisode: widget.onNextEpisode,
            onBackPressed: widget.onBackPressed,
          ),
        ],
      ),
    );
  }

  Future<void> _requestCast() async {
    final request = widget.onCastRequested;
    if (request != null) await request();
  }
}
