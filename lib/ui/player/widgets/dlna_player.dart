import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/dlna_device.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/result.dart';
import '../view_models/dlna_cast_view_model.dart';
import 'dlna_player_controls.dart';

/// DLNAPlayer 的页面级控制器。
class DLNAPlayerController {
  DLNAPlayerController._(this._state);

  final _DLNAPlayerState _state;

  Future<Result<void>> updateVideoUrl(
    String url,
    String title, {
    Duration? startAt,
  }) => _state.updateVideoUrl(url, title, startAt: startAt ?? Duration.zero);

  Duration get currentPosition =>
      _state.widget.castViewModel.playbackState.position;
}

/// 只负责渲染和转发交互的 DLNA 播放器视图。
class DLNAPlayer extends StatefulWidget {
  const DLNAPlayer({
    super.key,
    required this.device,
    required this.castViewModel,
    this.onBackPressed,
    this.onNextEpisode,
    this.isLastEpisode = false,
    this.onChangeDevice,
    this.resumePosition,
    this.onStopCasting,
    this.onProgressUpdate,
    this.onPause,
    this.onReady,
    this.onFailure,
    this.onControllerCreated,
    this.onVideoCompleted,
  });

  final DiscoveredDlnaDevice device;
  final DlnaCastViewModel castViewModel;
  final VoidCallback? onBackPressed;
  final VoidCallback? onNextEpisode;
  final bool isLastEpisode;
  final VoidCallback? onChangeDevice;
  final Duration? resumePosition;
  final ValueChanged<Duration>? onStopCasting;
  final void Function(Duration position, Duration duration)? onProgressUpdate;
  final VoidCallback? onPause;
  final VoidCallback? onReady;
  final ValueChanged<AppFailure>? onFailure;
  final ValueChanged<DLNAPlayerController>? onControllerCreated;
  final VoidCallback? onVideoCompleted;

  @override
  State<DLNAPlayer> createState() => _DLNAPlayerState();
}

class _DLNAPlayerState extends State<DLNAPlayer> {
  late DlnaPlaybackState _lastState;

  @override
  void initState() {
    super.initState();
    _setPortraitOrientation();
    _lastState = widget.castViewModel.playbackState;
    widget.castViewModel.addListener(_handlePlaybackChanged);
    widget.castViewModel.startPlaybackMonitoring(
      widget.device,
      resumePosition: widget.resumePosition,
    );
    widget.onControllerCreated?.call(DLNAPlayerController._(this));
  }

  @override
  void didUpdateWidget(covariant DLNAPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.castViewModel, oldWidget.castViewModel)) {
      oldWidget.castViewModel.removeListener(_handlePlaybackChanged);
      oldWidget.castViewModel.stopPlaybackMonitoring();
      widget.castViewModel.addListener(_handlePlaybackChanged);
    }
    if (widget.device.id != oldWidget.device.id ||
        !identical(widget.castViewModel, oldWidget.castViewModel)) {
      _lastState = widget.castViewModel.playbackState;
      widget.castViewModel.startPlaybackMonitoring(
        widget.device,
        resumePosition: widget.resumePosition,
      );
    }
  }

  void _handlePlaybackChanged() {
    if (!mounted) return;
    final next = widget.castViewModel.playbackState;
    final becameReady =
        _lastState.loading &&
        !next.loading &&
        next.deviceId == widget.device.id &&
        next.duration > Duration.zero;
    final becameCompleted = !_lastState.completed && next.completed;
    final progressChanged =
        _lastState.position != next.position ||
        _lastState.duration != next.duration;
    final becameFailed = _lastState.failure == null && next.failure != null;
    _lastState = next;
    setState(() {});
    if (becameReady) widget.onReady?.call();
    if (!next.loading && progressChanged) {
      widget.onProgressUpdate?.call(next.position, next.duration);
    }
    if (becameCompleted) widget.onVideoCompleted?.call();
    if (becameFailed) widget.onFailure?.call(next.failure!);
  }

  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _restoreOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _togglePlayPause() async {
    final wasPlaying = widget.castViewModel.playbackState.playing;
    final result = await widget.castViewModel.togglePlayback();
    if (!mounted || result.isFailure) return;
    if (wasPlaying) widget.onPause?.call();
  }

  void _stop() {
    widget.onStopCasting?.call(widget.castViewModel.playbackState.position);
  }

  Future<Result<void>> updateVideoUrl(
    String url,
    String title, {
    required Duration startAt,
  }) async {
    if (!mounted) {
      return const FailureResult<void>(
        AppFailure(kind: FailureKind.cancellation, message: '投屏页面已关闭'),
      );
    }

    AppLogger.debug('DLNA 播放地址已更新');
    widget.castViewModel.stopPlaybackMonitoring();
    final result = await widget.castViewModel.connect(
      widget.device,
      mediaUrl: url,
      title: title,
    );
    if (mounted && result.isSuccess) {
      _lastState = widget.castViewModel.playbackState;
      widget.castViewModel.startPlaybackMonitoring(
        widget.device,
        resumePosition: startAt,
      );
    }
    return result;
  }

  @override
  void dispose() {
    widget.castViewModel.removeListener(_handlePlaybackChanged);
    widget.castViewModel.stopPlaybackMonitoring();
    _restoreOrientation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.castViewModel.playbackState;
    return Container(
      color: Colors.black,
      child: DLNAPlayerControls(
        deviceName: widget.device.friendlyName,
        position: state.position,
        duration: state.duration,
        isPlaying: state.playing,
        isLoading: state.loading,
        onBackPressed: widget.onBackPressed,
        onNextEpisode: widget.onNextEpisode,
        isLastEpisode: widget.isLastEpisode,
        onPlayPause: () => unawaited(_togglePlayPause()),
        onStop: _stop,
        onSeek: (position) =>
            unawaited(widget.castViewModel.seekPlayback(position)),
        onVolumeChange: (volume) =>
            unawaited(widget.castViewModel.setPlaybackVolume(volume)),
        onChangeDevice: widget.onChangeDevice,
      ),
    );
  }
}
