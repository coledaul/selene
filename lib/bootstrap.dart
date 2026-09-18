import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:macos_window_utils/macos_window_utils.dart';
import 'package:media_kit/media_kit.dart';

import 'app/app_dependencies.dart';
import 'app/selene_app.dart';
import 'app/windows_window_setup.dart';
import 'data/services/douban_cache_service.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  if (Platform.isWindows) {
    await configureWindowsWindow();
  }

  if (Platform.isMacOS) {
    await WindowManipulator.initialize(enableWindowDelegate: true);
    await WindowManipulator.makeTitlebarTransparent();
    await WindowManipulator.enableFullSizeContentView();
    await WindowManipulator.hideTitle();
  }

  final doubanCacheService = DoubanCacheService();
  await doubanCacheService.init();
  doubanCacheService.startPeriodicCleanup();

  final dependencies = AppDependencies.create(
    doubanCacheService: doubanCacheService,
  )..start();
  runApp(SeleneApp(dependencies: dependencies));
}
