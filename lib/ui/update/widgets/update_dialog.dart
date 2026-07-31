import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/app_update_transfer.dart';
import '../../../domain/models/app_version.dart';
import '../../../utils/font_utils.dart';
import '../../../utils/result.dart';
import '../../core/view_models/theme_view_model.dart';
import '../view_models/update_view_model.dart';
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
    return Consumer2<ThemeViewModel, UpdateViewModel>(
      builder: (context, theme, update, child) {
        final dark = theme.isDarkMode;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF2C2C2C) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(dark: dark),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _VersionCard(versionInfo: versionInfo, dark: dark),
                        if (versionInfo.releaseNotes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _ReleaseNotes(
                            notes: versionInfo.releaseNotes,
                            dark: dark,
                          ),
                        ],
                        if (update.canDownloadInApp) ...[
                          const SizedBox(height: 16),
                          UpdateTransferPanel(
                            viewModel: update,
                            dark: dark,
                            onResult: (result) =>
                                _showUpdateFailure(context, result),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                _Actions(
                  versionInfo: versionInfo,
                  viewModel: update,
                  onDismissVersion: onDismissVersion,
                ),
              ],
            ),
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

final class _Header extends StatelessWidget {
  const _Header({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF333333) : const Color(0xFFF5F5F5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF27AE60).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              size: 40,
              color: Color(0xFF27AE60),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '发现新版本',
            style: FontUtils.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: dark ? Colors.white : const Color(0xFF2C2C2C),
            ),
          ),
        ],
      ),
    );
  }
}

final class _VersionCard extends StatelessWidget {
  const _VersionCard({required this.versionInfo, required this.dark});

  final AppVersionInfo versionInfo;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF333333) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _VersionValue(
              label: '当前版本',
              version: versionInfo.currentVersion,
              color: dark ? const Color(0xFF999999) : const Color(0xFF666666),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: dark ? const Color(0xFF444444) : const Color(0xFFDDDDDD),
          ),
          Expanded(
            child: _VersionValue(
              label: '最新版本',
              version: versionInfo.latestVersion,
              color: const Color(0xFF27AE60),
            ),
          ),
        ],
      ),
    );
  }
}

final class _VersionValue extends StatelessWidget {
  const _VersionValue({
    required this.label,
    required this.version,
    required this.color,
  });

  final String label;
  final String version;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: FontUtils.poppins(fontSize: 12, color: color)),
        const SizedBox(height: 2),
        Text(
          version,
          style: FontUtils.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

final class _ReleaseNotes extends StatelessWidget {
  const _ReleaseNotes({required this.notes, required this.dark});

  final String notes;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.article_outlined,
              size: 18,
              color: Color(0xFF27AE60),
            ),
            const SizedBox(width: 6),
            Text(
              '更新内容',
              style: FontUtils.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: dark ? Colors.white : const Color(0xFF2C2C2C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF333333) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: GptMarkdown(
              notes,
              style: FontUtils.poppins(
                fontSize: 14,
                height: 1.6,
                color: dark ? const Color(0xFFCCCCCC) : const Color(0xFF666666),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final class _Actions extends StatelessWidget {
  const _Actions({
    required this.versionInfo,
    required this.viewModel,
    required this.onDismissVersion,
  });

  final AppVersionInfo versionInfo;
  final UpdateViewModel viewModel;
  final Future<void> Function(String version) onDismissVersion;

  @override
  Widget build(BuildContext context) {
    final inApp = viewModel.canDownloadInApp;
    final transfer = viewModel.transfer;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _primaryEnabled(inApp, transfer)
                  ? () => _primaryAction(context, inApp, transfer)
                  : null,
              icon: Icon(_primaryIcon(inApp, transfer), size: 18),
              label: Text(
                _primaryLabel(inApp, transfer),
                style: FontUtils.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          if (inApp) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: viewModel.openRelease.running
                  ? null
                  : () => _openRelease(context),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('使用浏览器下载'),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    await onDismissVersion(versionInfo.latestVersion);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Text('忽略', style: FontUtils.poppins(fontSize: 14)),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('稍后', style: FontUtils.poppins(fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _primaryEnabled(bool inApp, UpdateTransferState transfer) {
    if (!inApp) return !viewModel.openRelease.running;
    return switch (transfer.phase) {
      UpdateTransferPhase.queued ||
      UpdateTransferPhase.downloading ||
      UpdateTransferPhase.verifying ||
      UpdateTransferPhase.awaitingPermission => false,
      _ => true,
    };
  }

  String _primaryLabel(bool inApp, UpdateTransferState transfer) {
    if (!inApp) return '查看新版本';
    return switch (transfer.phase) {
      UpdateTransferPhase.idle => '应用内下载',
      UpdateTransferPhase.queued => '等待下载…',
      UpdateTransferPhase.downloading =>
        '下载中 ${(transfer.progress * 100).round()}%',
      UpdateTransferPhase.paused => '继续下载',
      UpdateTransferPhase.verifying => '正在校验…',
      UpdateTransferPhase.readyToInstall => '安装更新',
      UpdateTransferPhase.awaitingPermission => '等待系统授权…',
      UpdateTransferPhase.installerLaunched => '再次打开安装器',
      UpdateTransferPhase.failed => '重新下载',
      UpdateTransferPhase.cancelled => '重新下载',
    };
  }

  IconData _primaryIcon(bool inApp, UpdateTransferState transfer) {
    if (!inApp) return Icons.open_in_new_rounded;
    return switch (transfer.phase) {
      UpdateTransferPhase.readyToInstall ||
      UpdateTransferPhase.installerLaunched => Icons.install_mobile_rounded,
      UpdateTransferPhase.paused => Icons.play_arrow_rounded,
      _ => Icons.download_rounded,
    };
  }

  Future<void> _primaryAction(
    BuildContext context,
    bool inApp,
    UpdateTransferState transfer,
  ) async {
    if (!inApp) {
      await _openRelease(context);
      return;
    }
    final result = switch (transfer.phase) {
      UpdateTransferPhase.paused => await viewModel.resume.execute(),
      UpdateTransferPhase.readyToInstall ||
      UpdateTransferPhase.installerLaunched =>
        await viewModel.install.execute(),
      _ => await viewModel.download.execute(),
    };
    if (context.mounted) _showUpdateFailure(context, result);
  }

  Future<void> _openRelease(BuildContext context) async {
    final result = await viewModel.openRelease.execute();
    if (!context.mounted) return;
    if (_showUpdateFailure(context, result)) return;
    Navigator.of(context).pop();
  }
}

bool _showUpdateFailure(BuildContext context, Result<void>? result) {
  final failure = result?.failureOrNull;
  if (failure == null) return false;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(failure.message)));
  return true;
}
