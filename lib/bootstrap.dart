import 'dart:io' show Platform;

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:macos_window_utils/macos_window_utils.dart';
import 'package:media_kit/media_kit.dart';

import 'app/app_dependencies.dart';
import 'app/selene_app.dart';
import 'data/services/douban_cache_service.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

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

  if (Platform.isWindows) {
    doWhenWindowReady(() {
      const initialSize = Size(1024, 600);
      appWindow
        ..minSize = initialSize
        ..size = initialSize
        ..alignment = Alignment.center
        ..title = 'Selene'
        ..show();
    });
  }
}
