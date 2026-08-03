import 'package:flutter/material.dart';

import '../../../domain/models/video_download_task.dart';
import '../../../utils/device_utils.dart';
import '../../core/widgets/app_page_bar.dart';
import '../../player/video_playback_session.dart';
import '../../player/widgets/video_player_surface.dart';
import '../../player/widgets/video_player_widget.dart';

typedef DownloadedPlayerBuilder =
    Widget Function({
      required VideoDownloadTask task,
      required String filePath,
      required String overlayTitle,
      required VoidCallback onBackPressed,
    });

/// 完成下载后的本地播放页；正常播放时导航完全交给播放器控制层。
final class DownloadedVideoPlayerScreen extends StatelessWidget {
  const DownloadedVideoPlayerScreen({
    super.key,
    required this.task,
    this.playerBuilder,
  });

  final VideoDownloadTask task;

  /// 隔离页面导航与原生播放器初始化，便于独立验证标题和返回合同。
  final DownloadedPlayerBuilder? playerBuilder;

  @override
  Widget build(BuildContext context) {
    final filePath = task.filePath;
    final title = '${task.title} · ${task.episodeTitle}';
    if (filePath == null) {
      return Scaffold(
        appBar: AppPageBar(title: title),
        body: const Center(child: Text('本地文件不存在')),
      );
    }

    void onBackPressed() => Navigator.of(context).maybePop();
    return Scaffold(
      backgroundColor: Colors.black,
      body:
          playerBuilder?.call(
            task: task,
            filePath: filePath,
            overlayTitle: title,
            onBackPressed: onBackPressed,
          ) ??
          _buildPlayer(
            task: task,
            filePath: filePath,
            overlayTitle: title,
            onBackPressed: onBackPressed,
          ),
    );
  }

  static Widget _buildPlayer({
    required VideoDownloadTask task,
    required String filePath,
    required String overlayTitle,
    required VoidCallback onBackPressed,
  }) => VideoPlayerWidget(
    surface: DeviceUtils.isPC()
        ? VideoPlayerSurface.desktop
        : VideoPlayerSurface.mobile,
    url: filePath,
    videoTitle: task.title,
    overlayTitle: overlayTitle,
    currentEpisodeIndex: task.episodeIndex,
    totalEpisodes: task.totalEpisodes,
    sourceName: task.sourceName,
    isLastEpisode: task.episodeIndex >= task.totalEpisodes - 1,
    mediaKind: PlaybackMediaKind.localFile,
    onBackPressed: onBackPressed,
  );
}
