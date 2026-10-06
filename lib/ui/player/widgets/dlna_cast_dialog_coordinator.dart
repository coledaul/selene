import 'package:flutter/material.dart';

import '../../../domain/models/dlna_device.dart';
import '../../../utils/result.dart';
import '../view_models/dlna_cast_view_model.dart';
import 'dlna_device_dialog.dart';

typedef DlnaCastConnect =
    Future<Result<void>> Function(DiscoveredDlnaDevice device);

/// 复用设备选择、最近设备读取和连接结果处理的投屏弹窗协调器。
final class DlnaCastDialogCoordinator {
  const DlnaCastDialogCoordinator._();

  static Future<void> show({
    required BuildContext context,
    required DlnaCastViewModel viewModel,
    required DiscoveredDlnaDevice? currentDevice,
    required DlnaCastConnect onConnect,
    required ValueChanged<DiscoveredDlnaDevice> onCastStarted,
    Future<void>? recentDeviceLoad,
  }) async {
    await (recentDeviceLoad ?? viewModel.loadRecentDevice());
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => DLNADeviceDialog(
        currentDevice: currentDevice,
        recentDevice: viewModel.recentDevice,
        castViewModel: viewModel,
        onConnect: onConnect,
        onCastStarted: onCastStarted,
      ),
    );
  }
}
