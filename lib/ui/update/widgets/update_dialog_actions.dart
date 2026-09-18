import 'package:flutter/material.dart';

import '../../../domain/models/app_update_transfer.dart';
import '../../../utils/result.dart';
import '../../core/themes/app_button_styles.dart';
import '../view_models/update_view_model.dart';
import 'update_state_cross_fade.dart';

/// 固定在滚动正文之外；每个阶段只有一个主操作。
final class UpdateDialogActions extends StatelessWidget {
  const UpdateDialogActions({
    super.key,
    required this.viewModel,
    required this.onDismissVersion,
    required this.onResult,
  });

  final UpdateViewModel viewModel;
  final Future<void> Function() onDismissVersion;
  final void Function(Result<void>? result) onResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inApp = viewModel.canDownloadInApp;
    final transfer = viewModel.displayTransfer;
    final busy = viewModel.transferCommandRunning;
    final downloadControls = inApp && transfer.canCancel;
    final waiting = !inApp
        ? viewModel.openRelease.running
        : busy ||
              transfer.phase == UpdateTransferPhase.queued ||
              transfer.phase == UpdateTransferPhase.verifying ||
              transfer.phase == UpdateTransferPhase.awaitingPermission;
    final showIgnore =
        !inApp ||
        transfer.phase == UpdateTransferPhase.idle ||
        transfer.phase == UpdateTransferPhase.cancelled;
    final primaryLabel = _primaryLabel(inApp, transfer);
    final primaryButton = FilledButton(
      key: const ValueKey('update-primary-action'),
      style: AppButtonStyles.filled(context, loading: waiting),
      onPressed: _primaryEnabled(inApp, transfer)
          ? () => _primaryAction(context)
          : null,
      child: Semantics(
        value: waiting ? '正在处理更新操作' : null,
        child: downloadControls
            ? UpdateStateCrossFade(
                showSecond: transfer.phase == UpdateTransferPhase.paused,
                alignment: Alignment.center,
                firstChild: const Text('暂停下载', textAlign: TextAlign.center),
                secondChild: const Text('继续下载', textAlign: TextAlign.center),
              )
            : Text(primaryLabel, textAlign: TextAlign.center),
      ),
    );
    final String? secondaryLabel;
    final VoidCallback? secondaryAction;
    if (downloadControls) {
      secondaryLabel = '取消下载';
      secondaryAction = busy
          ? null
          : () {
              if (viewModel.transferCommandRunning) return;
              _execute(context, viewModel.cancel.execute());
            };
    } else if (viewModel.canUseBrowserDownload) {
      secondaryLabel = viewModel.openRelease.running ? '正在打开…' : '浏览器下载';
      secondaryAction = viewModel.openRelease.running
          ? null
          : () => _openRelease(context);
    } else if (showIgnore) {
      secondaryLabel = '忽略此版本';
      secondaryAction = busy
          ? null
          : () async {
              await onDismissVersion();
              if (context.mounted && _isCurrentDialog(context)) {
                Navigator.of(context).pop();
              }
            };
    } else {
      secondaryLabel = null;
      secondaryAction = null;
    }
    final secondaryButton = secondaryLabel == null
        ? null
        : FilledButton(
            key: const ValueKey('update-secondary-action'),
            style: AppButtonStyles.filled(
              context,
              loading: busy || viewModel.openRelease.running,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            onPressed: secondaryAction,
            child: Text(secondaryLabel, textAlign: TextAlign.center),
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: LayoutBuilder(
        key: const ValueKey('update-actions-layout'),
        builder: (context, constraints) {
          final halfWidth = (constraints.maxWidth - 12) / 2;
          final fits =
              secondaryLabel != null &&
              _labelFits(context, primaryLabel, halfWidth) &&
              _labelFits(context, secondaryLabel, halfWidth);
          if (secondaryButton != null && fits) {
            return Row(
              children: [
                Expanded(child: secondaryButton),
                const SizedBox(width: 12),
                Expanded(child: primaryButton),
              ],
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (secondaryButton != null) ...[
                secondaryButton,
                const SizedBox(height: 12),
              ],
              primaryButton,
            ],
          );
        },
      ),
    );
  }

  // 按实际主题字体和系统字号决定换行，不用设备宽度或固定字号推测。
  bool _labelFits(BuildContext context, String label, double width) {
    final theme = Theme.of(context);
    final style = theme.filledButtonTheme.style;
    final padding = style?.padding
        ?.resolve({})
        ?.resolve(Directionality.of(context));
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: style?.textStyle?.resolve({}) ?? theme.textTheme.labelLarge,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final fits = painter.width + (padding?.horizontal ?? 32) <= width;
    painter.dispose();
    return fits;
  }

  bool _primaryEnabled(bool inApp, UpdateTransferState transfer) {
    if (!inApp) return !viewModel.openRelease.running;
    if (viewModel.transferCommandRunning) return false;
    return switch (transfer.phase) {
      UpdateTransferPhase.queued ||
      UpdateTransferPhase.verifying ||
      UpdateTransferPhase.awaitingPermission => false,
      _ => true,
    };
  }

  String _primaryLabel(bool inApp, UpdateTransferState transfer) {
    if (!inApp) return viewModel.openRelease.running ? '正在打开…' : '查看新版本';
    return switch (transfer.phase) {
      UpdateTransferPhase.idle || UpdateTransferPhase.cancelled => '立即更新',
      UpdateTransferPhase.queued || UpdateTransferPhase.downloading => '暂停下载',
      UpdateTransferPhase.paused => '继续下载',
      UpdateTransferPhase.verifying => '正在检查…',
      UpdateTransferPhase.readyToInstall => '安装更新',
      UpdateTransferPhase.awaitingPermission => '等待授权…',
      UpdateTransferPhase.installerLaunched => '再次安装',
      UpdateTransferPhase.failed => '重试下载',
    };
  }

  Future<void> _primaryAction(BuildContext context) async {
    if (!_primaryEnabled(viewModel.canDownloadInApp, viewModel.transfer)) {
      return;
    }
    if (!viewModel.canDownloadInApp) return _openRelease(context);
    final operation = switch (viewModel.transfer.phase) {
      UpdateTransferPhase.downloading => viewModel.pause.execute(),
      UpdateTransferPhase.paused => viewModel.resume.execute(),
      UpdateTransferPhase.readyToInstall ||
      UpdateTransferPhase.installerLaunched => viewModel.install.execute(),
      _ => viewModel.download.execute(),
    };
    await _execute(context, operation);
  }

  Future<void> _execute(
    BuildContext context,
    Future<Result<void>?> operation,
  ) async {
    final result = await operation;
    if (context.mounted && _isCurrentDialog(context)) onResult(result);
  }

  Future<void> _openRelease(BuildContext context) async {
    final result = await viewModel.openRelease.execute();
    if (!context.mounted || !_isCurrentDialog(context)) return;
    onResult(result);
    if (result is Success<void>) Navigator.of(context).pop();
  }

  // 弹窗退出动画期间 context 仍 mounted，异步返回不能再次 pop 底层页面。
  bool _isCurrentDialog(BuildContext context) =>
      ModalRoute.of(context)?.isCurrent == true;
}
