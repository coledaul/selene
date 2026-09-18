import 'package:flutter/material.dart';

import '../../../domain/models/app_update_transfer.dart';
import 'update_state_cross_fade.dart';

/// 只展示用户需要的下载状态；传输策略和操作编排由上层负责。
final class UpdateTransferPanel extends StatelessWidget {
  const UpdateTransferPanel({super.key, required this.transfer});

  final UpdateTransferState transfer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusStyle = theme.textTheme.bodyLarge?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final showProgress = switch (transfer.phase) {
      UpdateTransferPhase.queued ||
      UpdateTransferPhase.downloading ||
      UpdateTransferPhase.paused ||
      UpdateTransferPhase.verifying => true,
      _ => false,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (transfer.canCancel)
          UpdateStateCrossFade(
            showSecond: transfer.phase == UpdateTransferPhase.paused,
            firstChild: Text(_downloadingLabel, style: statusStyle),
            secondChild: Text('下载已暂停', style: statusStyle),
          )
        else
          Text(_statusLabel, style: statusStyle),
        if (showProgress) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value:
                transfer.phase == UpdateTransferPhase.verifying ||
                    transfer.totalBytes <= 0
                ? null
                : transfer.progress.clamp(0.0, 1.0),
            minHeight: 6,
            borderRadius: BorderRadius.circular(99),
            semanticsLabel: '更新下载进度',
          ),
          if (transfer.totalBytes > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${_formatBytes(transfer.downloadedBytes)} / ${_formatBytes(transfer.totalBytes)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
        if (transfer.errorMessage case final message?) ...[
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }

  String get _statusLabel => switch (transfer.phase) {
    UpdateTransferPhase.idle || UpdateTransferPhase.cancelled => '',
    UpdateTransferPhase.queued ||
    UpdateTransferPhase.downloading => _downloadingLabel,
    UpdateTransferPhase.paused => '下载已暂停',
    UpdateTransferPhase.verifying => '正在检查安装包…',
    UpdateTransferPhase.readyToInstall => '下载完成，可以安装了',
    UpdateTransferPhase.awaitingPermission => '请在系统设置中允许安装此应用',
    UpdateTransferPhase.installerLaunched => '请按系统提示完成安装',
    UpdateTransferPhase.failed => '下载未完成',
  };

  String get _downloadingLabel => transfer.totalBytes > 0
      ? '正在下载 ${(transfer.progress.clamp(0.0, 1.0) * 100).round()}%'
      : '正在下载…';

  static String _formatBytes(int value) {
    if (value < 1024) return '$value B';
    final kilobytes = value / 1024;
    if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
    return '${(kilobytes / 1024).toStringAsFixed(1)} MB';
  }
}
