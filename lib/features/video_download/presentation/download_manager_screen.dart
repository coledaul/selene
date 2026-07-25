import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../utils/device_utils.dart';
import '../../../widgets/video_player_surface.dart';
import '../../../widgets/video_player_widget.dart';
import '../application/video_download_manager.dart';
import '../domain/video_download_task.dart';
import 'download_settings_dialog.dart';

class DownloadManagerScreen extends StatelessWidget {
  const DownloadManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('下载管理'),
        actions: [
          IconButton(
            tooltip: '下载设置',
            onPressed: () => _showDownloadSettings(context),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Consumer<VideoDownloadManager>(
        builder: (context, manager, _) {
          if (!manager.isInitialized) {
            if (manager.initializationError != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 44),
                      const SizedBox(height: 12),
                      Text(manager.initializationError!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: manager.initialize,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
          if (manager.tasks.isEmpty) {
            return const _EmptyDownloads();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: manager.tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _DownloadTaskCard(
              task: manager.tasks[index],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDownloadSettings(BuildContext context) async {
    final manager = context.read<VideoDownloadManager>();
    final selected = await showDownloadSettingsDialog(
      context: context,
      currentValue: manager.maxConcurrentDownloads,
    );
    if (selected == null || selected == manager.maxConcurrentDownloads) {
      return;
    }
    try {
      await manager.setMaxConcurrentDownloads(selected);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('下载设置保存失败，请重试')),
      );
    }
  }
}

class _EmptyDownloads extends StatelessWidget {
  const _EmptyDownloads();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download_for_offline_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('暂无下载任务', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              '在视频详情页点击下载按钮，可选择单集或多集下载。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadTaskCard extends StatelessWidget {
  const _DownloadTaskCard({required this.task});

  final VideoDownloadTask task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCover(theme),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${task.episodeTitle} · ${task.sourceName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (task.status == VideoDownloadStatus.downloading ||
                      task.status == VideoDownloadStatus.finalizing) ...[
                    LinearProgressIndicator(
                      value: task.durationMs == null ? null : task.progress,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _statusText(task),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: task.status == VideoDownloadStatus.failed
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ..._actions(context),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 88,
        child: task.coverUrl.isEmpty
            ? ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.movie_outlined),
              )
            : CachedNetworkImage(
                imageUrl: task.coverUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                errorWidget: (_, __, ___) => ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context) {
    switch (task.status) {
      case VideoDownloadStatus.completed:
        return <Widget>[
          _actionButton(
            tooltip: '播放',
            icon: Icons.play_arrow_rounded,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DownloadedVideoPlayerScreen(task: task),
              ),
            ),
          ),
          _actionButton(
            tooltip: '删除',
            icon: Icons.delete_outline_rounded,
            onPressed: () => _confirmDelete(context),
          ),
        ];
      case VideoDownloadStatus.failed:
      case VideoDownloadStatus.cancelled:
        return <Widget>[
          _actionButton(
            tooltip: '重试',
            icon: Icons.refresh_rounded,
            onPressed: () =>
                context.read<VideoDownloadManager>().retry(task.id),
          ),
          _actionButton(
            tooltip: '删除',
            icon: Icons.delete_outline_rounded,
            onPressed: () => _confirmDelete(context),
          ),
        ];
      case VideoDownloadStatus.queued:
      case VideoDownloadStatus.probing:
      case VideoDownloadStatus.downloading:
      case VideoDownloadStatus.finalizing:
        return <Widget>[
          _actionButton(
            tooltip: '取消',
            icon: Icons.close_rounded,
            onPressed: () =>
                context.read<VideoDownloadManager>().cancel(task.id),
          ),
        ];
    }
  }

  Widget _actionButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      tooltip: tooltip,
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除下载'),
        content: Text('确定删除“${task.title} · ${task.episodeTitle}”及本地文件吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<VideoDownloadManager>().delete(task.id);
    }
  }

  static String _statusText(VideoDownloadTask task) {
    switch (task.status) {
      case VideoDownloadStatus.queued:
        return '等待下载';
      case VideoDownloadStatus.probing:
        return '正在读取媒体信息';
      case VideoDownloadStatus.downloading:
        final size = _formatBytes(task.downloadedBytes);
        final progress = task.durationMs == null
            ? ''
            : ' · ${(task.progress * 100).toStringAsFixed(0)}%';
        final speed = task.bytesPerSecond == null || task.bytesPerSecond! <= 0
            ? ''
            : ' · ${_formatBytes(task.bytesPerSecond!.round())}/s';
        return '下载中 · $size$progress$speed';
      case VideoDownloadStatus.finalizing:
        return '正在校验并整理文件';
      case VideoDownloadStatus.completed:
        return '已完成 · ${_formatBytes(task.downloadedBytes)}';
      case VideoDownloadStatus.failed:
        return task.errorMessage ?? '下载失败';
      case VideoDownloadStatus.cancelled:
        return '已取消';
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kib = bytes / 1024;
    if (kib < 1024) return '${kib.toStringAsFixed(1)} KB';
    final mib = kib / 1024;
    if (mib < 1024) return '${mib.toStringAsFixed(1)} MB';
    return '${(mib / 1024).toStringAsFixed(2)} GB';
  }
}

class DownloadedVideoPlayerScreen extends StatelessWidget {
  const DownloadedVideoPlayerScreen({
    super.key,
    required this.task,
  });

  final VideoDownloadTask task;

  @override
  Widget build(BuildContext context) {
    final filePath = task.filePath;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${task.title} · ${task.episodeTitle}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: filePath == null
          ? const Center(
              child: Text('本地文件不存在', style: TextStyle(color: Colors.white)),
            )
          : VideoPlayerWidget(
              surface: DeviceUtils.isPC()
                  ? VideoPlayerSurface.desktop
                  : VideoPlayerSurface.mobile,
              url: filePath,
              videoTitle: task.title,
              currentEpisodeIndex: task.episodeIndex,
              totalEpisodes: task.totalEpisodes,
              sourceName: task.sourceName,
              isLastEpisode: task.episodeIndex >= task.totalEpisodes - 1,
              onBackPressed: () => Navigator.of(context).maybePop(),
            ),
    );
  }
}
