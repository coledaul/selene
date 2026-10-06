import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/dlna_device.dart';
import '../../../domain/models/video_download_task.dart';
import '../../../utils/device_utils.dart';
import '../../../utils/result.dart';
import '../../core/widgets/app_page_bar.dart';
import '../../player/video_playback_session.dart';
import '../../player/view_models/dlna_cast_view_model.dart';
import '../../player/widgets/dlna_cast_dialog_coordinator.dart';
import '../../player/widgets/dlna_player.dart';
import '../../player/widgets/video_player_surface.dart';
import '../../player/widgets/video_player_widget.dart';

typedef DownloadedPlayerBuilder =
    Widget Function({
      required VideoDownloadTask task,
      required String filePath,
      required String overlayTitle,
      required VoidCallback onBackPressed,
    });

/// 完成下载后的本地播放页，投屏时仍使用同一份本地文件。
final class DownloadedVideoPlayerScreen extends StatefulWidget {
  const DownloadedVideoPlayerScreen({
    super.key,
    required this.task,
    this.playerBuilder,
    this.dlnaCastViewModelFactory,
  });

  final VideoDownloadTask task;
  final DownloadedPlayerBuilder? playerBuilder;
  final DlnaCastViewModel Function()? dlnaCastViewModelFactory;

  @override
  State<DownloadedVideoPlayerScreen> createState() =>
      _DownloadedVideoPlayerScreenState();
}

final class _DownloadedVideoPlayerScreenState
    extends State<DownloadedVideoPlayerScreen> {
  DlnaCastViewModel? _castViewModel;
  VideoPlayerWidgetController? _localController;
  DiscoveredDlnaDevice? _device;
  bool _casting = false;
  Duration? _castStartPosition;

  @override
  void initState() {
    super.initState();
    if (widget.task.filePath != null &&
        widget.dlnaCastViewModelFactory != null) {
      _castViewModel = widget.dlnaCastViewModelFactory!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filePath = widget.task.filePath;
    final title = '${widget.task.title} · ${widget.task.episodeTitle}';
    if (filePath == null) {
      return Scaffold(
        appBar: AppPageBar(title: title),
        body: const Center(child: Text('本地文件不存在')),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Offstage(
                offstage: _casting,
                child:
                    widget.playerBuilder?.call(
                      task: widget.task,
                      filePath: filePath,
                      overlayTitle: title,
                      onBackPressed: _handleBackPressed,
                    ) ??
                    _buildLocalPlayer(
                      filePath: filePath,
                      title: title,
                      onBackPressed: _handleBackPressed,
                    ),
              ),
              if (_casting && _device != null && _castViewModel != null)
                DLNAPlayer(
                  key: ValueKey<String>(_device!.id),
                  device: _device!,
                  castViewModel: _castViewModel!,
                  resumePosition: _castStartPosition,
                  onBackPressed: () => unawaited(_handleBackPressed()),
                  onStopCasting: (position) =>
                      unawaited(_stopCasting(position)),
                  onChangeDevice: () => unawaited(_showCastDialog()),
                  onFailure: _showFailure,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalPlayer({
    required String filePath,
    required String title,
    required VoidCallback onBackPressed,
  }) => VideoPlayerWidget(
    surface: DeviceUtils.isPC()
        ? VideoPlayerSurface.desktop
        : VideoPlayerSurface.mobile,
    url: filePath,
    videoTitle: widget.task.title,
    overlayTitle: title,
    currentEpisodeIndex: widget.task.episodeIndex,
    totalEpisodes: widget.task.totalEpisodes,
    sourceName: widget.task.sourceName,
    isLastEpisode: widget.task.episodeIndex >= widget.task.totalEpisodes - 1,
    mediaKind: PlaybackMediaKind.localFile,
    onBackPressed: onBackPressed,
    onCastRequested: _castViewModel == null ? null : _showCastDialog,
    onControllerCreated: (controller) => _localController = controller,
  );

  Future<void> _showCastDialog() async {
    final viewModel = _castViewModel;
    final controller = _localController;
    final filePath = widget.task.filePath;
    if (!mounted ||
        viewModel == null ||
        controller == null ||
        filePath == null) {
      return;
    }
    Duration? resumePosition;
    final wasCasting = _casting;
    final wasPlaying = !wasCasting && controller.isPlaying;
    final previousDevice = _device;
    await DlnaCastDialogCoordinator.show(
      context: context,
      viewModel: viewModel,
      currentDevice: previousDevice,
      onConnect: (device) async {
        resumePosition = wasCasting
            ? viewModel.playbackState.position
            : controller.currentPosition;
        if (wasPlaying) await controller.pause();
        final result = await viewModel.connectLocalFile(
          device,
          filePath: filePath,
          title: '${widget.task.title} · ${widget.task.episodeTitle}',
          previousDevice: previousDevice,
        );
        if (result.isFailure && wasPlaying && mounted) {
          await controller.play();
        }
        return result;
      },
      onCastStarted: (device) {
        if (!mounted) return;
        setState(() {
          _casting = true;
          _device = device;
          _castStartPosition = resumePosition;
        });
        unawaited(viewModel.rememberDevice(device.toRecentDevice()));
      },
    );
  }

  Future<void> _stopCasting(Duration position) async {
    final viewModel = _castViewModel;
    final device = _device;
    if (viewModel == null || device == null) return;
    final stopResult = await viewModel.stopPlayback(device);
    final releaseResult = await viewModel.releaseLocalMedia();
    if (!mounted) return;
    setState(() {
      _casting = false;
      _device = null;
      _castStartPosition = null;
    });
    final controller = _localController;
    if (controller != null) {
      await controller.seekTo(position);
      await controller.play();
    }
    if (stopResult.isFailure) {
      _showFailure(stopResult.failureOrNull!);
    } else if (releaseResult.isFailure) {
      _showFailure(releaseResult.failureOrNull!);
    }
  }

  Future<void> _handleBackPressed() async {
    if (_casting) {
      await _stopCasting(
        _castViewModel?.playbackState.position ?? Duration.zero,
      );
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  void _showFailure(AppFailure failure) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failure.message)));
  }

  @override
  void dispose() {
    final viewModel = _castViewModel;
    final device = _device;
    if (viewModel != null) {
      unawaited(_disposeCast(viewModel, device));
    }
    super.dispose();
  }

  Future<void> _disposeCast(
    DlnaCastViewModel viewModel,
    DiscoveredDlnaDevice? device,
  ) async {
    if (device != null) await viewModel.stopPlayback(device);
    viewModel.dispose();
  }
}
