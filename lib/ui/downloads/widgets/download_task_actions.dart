import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../domain/models/download_export_outcome.dart';
import '../../../domain/models/video_download_task.dart';
import '../../../utils/result.dart';
import '../../core/themes/app_tokens.dart';
import '../../core/widgets/app_icon_action_button.dart';
import '../../core/widgets/app_button_progress.dart';
import '../view_models/download_view_model.dart';
import 'downloaded_video_player_screen.dart';

enum _TaskMenuAction { export, delete }

/// 主操作直接可见，文件操作收进菜单；这里只管理页面反馈，不持有下载任务。
final class DownloadTaskActions extends StatefulWidget {
  const DownloadTaskActions({
    super.key,
    required this.task,
    required this.viewModel,
  });

  final VideoDownloadTask task;
  final DownloadViewModel viewModel;

  @override
  State<DownloadTaskActions> createState() => _DownloadTaskActionsState();
}

class _DownloadTaskActionsState extends State<DownloadTaskActions> {
  bool _running = false;
  bool _confirmingDelete = false;

  DownloadViewModel get _viewModel => widget.viewModel;
  bool get _blocked =>
      _running ||
      _confirmingDelete ||
      _viewModel.export.running ||
      _viewModel.retry.running ||
      _viewModel.cancel.running ||
      _viewModel.delete.running;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final colors = Theme.of(context).colorScheme;
    final completed = task.status == VideoDownloadStatus.completed;
    final retryable =
        task.status == VideoDownloadStatus.failed ||
        task.status == VideoDownloadStatus.cancelled;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (completed)
          AppIconActionButton(
            icon: LucideIcons.play,
            tooltip: '播放',
            foregroundColor: colors.primary,
            onPressed: _confirmingDelete || _viewModel.delete.running
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DownloadedVideoPlayerScreen(task: task),
                    ),
                  ),
          )
        else
          AppIconActionButton(
            icon: retryable ? LucideIcons.rotateCcw : LucideIcons.x,
            tooltip: retryable ? '重试' : '取消',
            foregroundColor: retryable ? colors.primary : null,
            loading: _running,
            onPressed: _blocked
                ? null
                : () => _run<void>(
                    () => retryable
                        ? _viewModel.retry.execute(task.id)
                        : _viewModel.cancel.execute(task.id),
                  ),
          ),
        if (completed || retryable)
          PopupMenuButton<_TaskMenuAction>(
            tooltip: '更多操作',
            enabled: !_blocked,
            padding: const EdgeInsets.all(12),
            iconSize: AppMetrics.actionIcon,
            style: IconButton.styleFrom(
              minimumSize: const Size.square(AppMetrics.touchTarget),
              maximumSize: const Size.square(AppMetrics.touchTarget),
              foregroundColor: colors.onSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppMetrics.iconButtonRadius,
                ),
              ),
            ),
            icon:
                completed && (_running || _viewModel.exportingTaskId == task.id)
                ? AppButtonProgress(
                    label: '正在处理文件',
                    size: 20,
                    color: colors.onSurfaceVariant,
                  )
                : const Icon(LucideIcons.ellipsis),
            onSelected: (action) {
              if (_blocked) return;
              switch (action) {
                case _TaskMenuAction.export:
                  _run<DownloadExportOutcome>(
                    () => _viewModel.export.execute(task.id),
                  );
                case _TaskMenuAction.delete:
                  _confirmDelete();
              }
            },
            itemBuilder: (context) => [
              if (completed)
                _menuItem(
                  _TaskMenuAction.export,
                  '导出',
                  LucideIcons.folderOutput,
                  colors.onSurface,
                ),
              _menuItem(
                _TaskMenuAction.delete,
                '删除',
                LucideIcons.trash2,
                colors.error,
              ),
            ],
          ),
      ],
    );
  }

  PopupMenuItem<_TaskMenuAction> _menuItem(
    _TaskMenuAction action,
    String label,
    IconData icon,
    Color color,
  ) {
    return PopupMenuItem(
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Flexible(
            child: Text(label, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }

  Future<void> _run<T>(Future<Result<T>?> Function() operation) async {
    if (_blocked) return;
    setState(() => _running = true);
    try {
      final result = await operation();
      if (!mounted || result == null) return;
      final failure = result.failureOrNull;
      if (failure != null) {
        _showMessage(failure.message);
      } else if (result.valueOrNull == DownloadExportOutcome.exported) {
        _showMessage('已导出');
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmDelete() async {
    if (_blocked) return;
    setState(() => _confirmingDelete = true);
    final task = widget.task;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除下载'),
        content: Text('确定删除“${task.title} · ${task.episodeTitle}”及本地文件吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _confirmingDelete = false);
    if (confirmed == true) {
      await _run<void>(() => _viewModel.delete.execute(task.id));
    }
  }
}
