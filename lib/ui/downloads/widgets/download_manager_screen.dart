import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:selene/ui/core/themes/app_button_styles.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:selene/domain/models/video_download_task.dart';
import 'package:selene/ui/core/widgets/app_page_bar.dart';
import 'package:selene/ui/downloads/view_models/download_view_model.dart';
import 'package:selene/utils/result.dart';
import 'download_settings_dialog.dart';
import 'download_task_actions.dart';

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
        actions: [
          IconButton(
            tooltip: '下载设置',
            onPressed: () => _showDownloadSettings(context),
            icon: const Icon(LucideIcons.settings2, size: 22),
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
                        style: AppButtonStyles.filled(
                          context,
                          loading: _viewModel.initialize.running,
                        ),
                        onPressed: _viewModel.initialize.running
                            ? null
                            : _viewModel.initialize.execute,
                        child: Text(
                          _viewModel.initialize.running ? '正在重试…' : '重试',
                        ),
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
              key: ValueKey(state.tasks[index].id),
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
              LucideIcons.download,
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
  const _DownloadTaskCard({
    super.key,
    required this.task,
    required this.viewModel,
  });

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
                  Text(
                    _statusText(task),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: task.status == VideoDownloadStatus.failed
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: DownloadTaskActions(
                      task: task,
                      viewModel: viewModel,
                    ),
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
