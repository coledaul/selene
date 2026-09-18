import 'dart:ui';

import 'package:window_manager/window_manager.dart';

/// 在 runApp 前配置窗口，原生 runner 仍负责第一帧绘制后显示。
Future<void> configureWindowsWindow() async {
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      size: Size(1024, 600),
      minimumSize: Size(1024, 600),
      center: true,
      title: 'Selene',
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    ),
  );
}
