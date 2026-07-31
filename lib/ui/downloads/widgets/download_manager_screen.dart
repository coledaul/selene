import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:selene/domain/models/download_export_outcome.dart';
import 'package:selene/domain/models/video_download_task.dart';
import 'package:selene/ui/core/widgets/app_page_bar.dart';
import 'package:selene/ui/downloads/view_models/download_view_model.dart';
import 'package:selene/utils/result.dart';
import 'downloaded_video_player_screen.dart';
import 'download_settings_dialog.dart';

class DownloadManagerScreen extends StatefulWidget {
  const DownloadManagerScreen({super.key, required this.viewModelFactory});

  final DownloadViewModel Function() viewModelFactory;

  @override
  State<DownloadManagerScreen> createState() => _DownloadManagerScreenState();
}

class _DownloadManagerScreenState extends State<DownloadManagerScreen> {
  late final DownloadViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModelFactory();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppPageBar(
        title: '下载管理',
        titleIcon: LucideIcons.download,
        titleIconColor: const Color(0xFF27AE60),
        actions: [
          IconButton(
            tooltip: '下载设置',
            onPressed: () => _showDownloadSettings(context),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final state = _viewModel.state;
          if (!state.initialized) {
            if (state.initializationError != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 44),
                      const SizedBox(height: 12),
                      Text(state.initializationError!),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _viewModel.initialize.execute,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
          if (state.tasks.isEmpty) {
            return const _EmptyDownloads();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: state.tasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _DownloadTaskCard(
              task: state.tasks[index],
              viewModel: _viewModel,
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDownloadSettings(BuildContext context) async {
    final selected = await showDownloadSettingsDialog(
      context: context,
      currentValue: _viewModel.state.maxConcurrentDownloads,
    );
    if (selected == null ||
        selected == _viewModel.state.maxConcurrentDownloads) {
      return;
    }
    final result = await _viewModel.setConcurrency.execute(selected);
    if (!context.mounted) return;
    if (result case FailureResult<void>()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('下载设置保存失败，请重试')));
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
  const _DownloadTaskCard({required this.task, required this.viewModel});

  final VideoDownloadTask task;
  final DownloadViewModel viewModel;

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
                placeholder: (_, _) => ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                errorWidget: (_, _, _) => ColoredBox(
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
          _exportButton(context),
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
            onPressed: () => viewModel.retry.execute(task.id),
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
            onPressed: () => viewModel.cancel.execute(task.id),
          ),
        ];
    }
  }

  Widget _actionButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      tooltip: tooltip,
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }

  Widget _exportButton(BuildContext context) {
    final isExporting = viewModel.exportingTaskId == task.id;
    return IconButton(
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      tooltip: '导出',
      onPressed: viewModel.export.running ? null : () => _export(context),
      icon: isExporting
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save_alt_rounded),
    );
  }

  Future<void> _export(BuildContext context) async {
    final result = await viewModel.export.execute(task.id);
    if (!context.mounted || result == null) {
      return;
    }
    if (result case Success<DownloadExportOutcome>(:final value)) {
      if (value == DownloadExportOutcome.exported) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已导出')));
      }
      return;
    }
    if (result case FailureResult<DownloadExportOutcome>(:final failure)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
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
      await viewModel.delete.execute(task.id);
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
