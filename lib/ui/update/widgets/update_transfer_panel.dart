import 'package:flutter/material.dart';

import '../../../domain/models/app_update_transfer.dart';
import '../../../utils/font_utils.dart';
import '../../../utils/result.dart';
import '../view_models/update_view_model.dart';

final class UpdateTransferPanel extends StatelessWidget {
  const UpdateTransferPanel({
    super.key,
    required this.viewModel,
    required this.dark,
    required this.onResult,
  });

  final UpdateViewModel viewModel;
  final bool dark;
  final void Function(Result<void>? result) onResult;

  @override
  Widget build(BuildContext context) {
    final transfer = viewModel.transfer;
    final asset = viewModel.versionInfo?.androidAsset;
    final foreground = dark ? Colors.white : const Color(0xFF2C2C2C);
    final secondary = dark ? const Color(0xFFBBBBBB) : const Color(0xFF666666);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF27AE60).withValues(alpha: dark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF27AE60).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Android 安装包',
                  style: FontUtils.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ),
              if (asset != null)
                Text(
                  _formatBytes(asset.size),
                  style: FontUtils.poppins(fontSize: 12, color: secondary),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '下载线路',
                style: FontUtils.poppins(fontSize: 13, color: secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UpdateDownloadSource>(
                    isDense: true,
                    isExpanded: true,
                    value: viewModel.downloadSource,
                    dropdownColor: dark
                        ? const Color(0xFF333333)
                        : Colors.white,
                    style: FontUtils.poppins(fontSize: 13, color: foreground),
                    onChanged: _canChangeSource(transfer)
                        ? (source) {
                            if (source != null) {
                              _execute(
                                context,
                                viewModel.setSource.execute(source),
                              );
                            }
                          }
                        : null,
                    items: UpdateDownloadSource.values
                        .map(
                          (source) => DropdownMenuItem(
                            value: source,
                            child: Text(_sourceLabel(source)),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
            ],
          ),
          if (transfer.phase != UpdateTransferPhase.idle) ...[
            const SizedBox(height: 12),
            Text(
              _statusLabel(transfer),
              style: FontUtils.poppins(fontSize: 13, color: foreground),
            ),
          ],
          if (_showsProgress(transfer)) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value:
                  transfer.phase == UpdateTransferPhase.queued ||
                      transfer.progress <= 0
                  ? null
                  : transfer.progress,
              minHeight: 6,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: const Color(0xFF27AE60).withValues(alpha: 0.15),
              color: const Color(0xFF27AE60),
            ),
            if (transfer.totalBytes > 0) ...[
              const SizedBox(height: 6),
              Text(
                '${_formatBytes(transfer.downloadedBytes)} / '
                '${_formatBytes(transfer.totalBytes)}',
                style: FontUtils.poppins(fontSize: 11, color: secondary),
              ),
            ],
          ],
          if (transfer.errorMessage case final message?) ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: FontUtils.poppins(
                fontSize: 12,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
          if (transfer.canPause || transfer.canResume || transfer.canCancel)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (transfer.canPause)
                    TextButton.icon(
                      onPressed: viewModel.pause.running
                          ? null
                          : () => _execute(context, viewModel.pause.execute()),
                      icon: const Icon(Icons.pause_rounded, size: 17),
                      label: const Text('暂停'),
                    ),
                  if (transfer.canResume)
                    TextButton.icon(
                      onPressed: viewModel.resume.running
                          ? null
                          : () => _execute(context, viewModel.resume.execute()),
                      icon: const Icon(Icons.play_arrow_rounded, size: 17),
                      label: const Text('继续'),
                    ),
                  if (transfer.canCancel)
                    TextButton.icon(
                      onPressed: viewModel.cancel.running
                          ? null
                          : () => _execute(context, viewModel.cancel.execute()),
                      icon: const Icon(Icons.close_rounded, size: 17),
                      label: const Text('取消'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _execute(
    BuildContext context,
    Future<Result<void>?> operation,
  ) async {
    final result = await operation;
    if (context.mounted) onResult(result);
  }

  static bool _canChangeSource(UpdateTransferState transfer) =>
      switch (transfer.phase) {
        UpdateTransferPhase.idle ||
        UpdateTransferPhase.failed ||
        UpdateTransferPhase.cancelled => true,
        _ => false,
      };

  static bool _showsProgress(UpdateTransferState transfer) =>
      switch (transfer.phase) {
        UpdateTransferPhase.queued ||
        UpdateTransferPhase.downloading ||
        UpdateTransferPhase.paused ||
        UpdateTransferPhase.verifying => true,
        _ => false,
      };

  static String _sourceLabel(UpdateDownloadSource source) => switch (source) {
    UpdateDownloadSource.automatic => '自动',
    UpdateDownloadSource.direct => 'GitHub 直连',
    UpdateDownloadSource.proxy => '加速地址',
  };

  static String _statusLabel(UpdateTransferState transfer) =>
      switch (transfer.phase) {
        UpdateTransferPhase.queued => '等待系统开始下载',
        UpdateTransferPhase.downloading =>
          '正在通过${_activeSourceLabel(transfer.activeSource)}下载',
        UpdateTransferPhase.paused => '下载已暂停',
        UpdateTransferPhase.verifying => '正在校验文件大小和 SHA-256',
        UpdateTransferPhase.readyToInstall => '安装包校验通过，可以安全交给系统安装器',
        UpdateTransferPhase.awaitingPermission => '等待系统授予安装来源权限',
        UpdateTransferPhase.installerLaunched => '已打开系统安装器；安装结果由 Android 决定',
        UpdateTransferPhase.failed => '更新下载失败',
        UpdateTransferPhase.cancelled => '更新下载已取消',
        UpdateTransferPhase.idle => '',
      };

  static String _activeSourceLabel(UpdateDownloadSource? source) =>
      switch (source) {
        UpdateDownloadSource.direct => ' GitHub 直连',
        UpdateDownloadSource.proxy => '加速地址',
        _ => '当前线路',
      };

  static String _formatBytes(int value) {
    if (value < 1024) return '$value B';
    final kilobytes = value / 1024;
    if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
    return '${(kilobytes / 1024).toStringAsFixed(1)} MB';
  }
}
