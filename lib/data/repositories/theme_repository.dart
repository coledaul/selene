import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../domain/models/app_theme_mode.dart';
import '../../utils/app_logger.dart';
import '../services/window_appearance_service.dart';

abstract interface class ThemeRepository implements Listenable {
  AppThemeMode get mode;
  bool get isDark;

  Future<void> setMode(AppThemeMode mode);
  void dispose();
}

final class DefaultThemeRepository extends ChangeNotifier
    implements ThemeRepository {
  DefaultThemeRepository({required WindowAppearanceService windowService})
    : _windowService = windowService;

  final WindowAppearanceService _windowService;
  AppThemeMode _mode = AppThemeMode.system;

  @override
  AppThemeMode get mode => _mode;

  @override
  bool get isDark => switch (_mode) {
    AppThemeMode.dark => true,
    AppThemeMode.light => false,
    AppThemeMode.system =>
      PlatformDispatcher.instance.platformBrightness.name == 'dark',
  };

  @override
  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    notifyListeners();
    try {
      await _windowService.apply(dark: isDark);
    } catch (error, stackTrace) {
      AppLogger.debug('更新窗口外观失败', error: error, stackTrace: stackTrace);
    }
  }
}
