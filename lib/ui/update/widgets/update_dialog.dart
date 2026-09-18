import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/app_update_transfer.dart';
import '../../../domain/models/app_version.dart';
import '../../../utils/result.dart';
import '../../core/widgets/app_icon_action_button.dart';
import '../view_models/update_view_model.dart';
import 'update_dialog_actions.dart';
import 'update_transfer_panel.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({
    super.key,
    required this.versionInfo,
    required this.onDismissVersion,
  });

  final AppVersionInfo versionInfo;
  final Future<void> Function(String version) onDismissVersion;

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateViewModel>(
      builder: (context, update, child) {
        final theme = Theme.of(context);
        final showTransfer =
            update.canDownloadInApp &&
            update.displayTransfer.phase != UpdateTransferPhase.idle &&
            update.displayTransfer.phase != UpdateTransferPhase.cancelled;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        showTransfer ? '更新版本' : '发现新版本',
                        style: theme.dialogTheme.titleTextStyle,
                      ),
                    ),
                    AppIconActionButton(
                      icon: Icons.close_rounded,
                      tooltip: '关闭更新弹窗',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // 只有正文滚动，关闭入口与底部操作始终可见。
              Flexible(
                child: SingleChildScrollView(
                  key: ValueKey(showTransfer),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _VersionLabel(versionInfo: versionInfo),
                      if (showTransfer) ...[
                        const SizedBox(height: 20),
                        UpdateTransferPanel(transfer: update.displayTransfer),
                      ] else if (versionInfo.releaseNotes
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          '更新内容',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _ReleaseNotes(notes: versionInfo.releaseNotes),
                      ],
                    ],
                  ),
                ),
              ),
              UpdateDialogActions(
                viewModel: update,
                onDismissVersion: () =>
                    onDismissVersion(versionInfo.latestVersion),
                onResult: (result) => _showUpdateFailure(context, result),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> show(
    BuildContext context,
    AppVersionInfo versionInfo, {
    required Future<void> Function(String version) onDismissVersion,
  }) async {
    context.read<UpdateViewModel>().prepare(versionInfo);
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateDialog(
        versionInfo: versionInfo,
        onDismissVersion: onDismissVersion,
      ),
    );
  }
}

final class _VersionLabel extends StatelessWidget {
  const _VersionLabel({required this.versionInfo});

  final AppVersionInfo versionInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '${versionInfo.currentVersion} → '),
          TextSpan(
            text: versionInfo.latestVersion,
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      style: theme.textTheme.bodySmall?.copyWith(
        color: colors.onSurfaceVariant,
      ),
    );
  }
}

final class _ReleaseNotes extends StatelessWidget {
  const _ReleaseNotes({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = theme.textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    return GptMarkdownTheme(
      gptThemeData: GptMarkdownTheme.of(context).copyWith(
        h1: heading,
        h2: heading,
        h3: heading,
        h4: heading,
        h5: heading,
        h6: heading,
        autoAddDividerLineAfterH1: false,
        linkColor: theme.colorScheme.primary,
        linkHoverColor: theme.colorScheme.primary,
      ),
      child: GptMarkdown(
        notes,
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.5,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

void _showUpdateFailure(BuildContext context, Result<void>? result) {
  final failure = result?.failureOrNull;
  if (failure == null) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(failure.message)));
}
