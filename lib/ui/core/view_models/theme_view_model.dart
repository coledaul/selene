import 'package:flutter/foundation.dart' show Brightness;

import '../../../data/repositories/theme_repository.dart';
import '../../../domain/models/app_theme_mode.dart';
import 'view_model.dart';

final class ThemeViewModel extends ViewModel {
  ThemeViewModel({required ThemeRepository repository})
    : _repository = repository {
    _repository.addListener(_sync);
  }

  final ThemeRepository _repository;

  AppThemeMode get mode => _repository.mode;
  bool get isDarkMode => _repository.isDark;

  Future<void> setThemeMode(AppThemeMode mode) => _repository.setMode(mode);

  Future<void> toggleTheme(Brightness platformBrightness) {
    final next = switch (_repository.mode) {
      AppThemeMode.light => AppThemeMode.dark,
      AppThemeMode.dark => AppThemeMode.light,
      AppThemeMode.system =>
        platformBrightness == Brightness.light
            ? AppThemeMode.dark
            : AppThemeMode.light,
    };
    return _repository.setMode(next);
  }

  void _sync() => notifyIfActive();

  @override
  void dispose() {
    _repository.removeListener(_sync);
    super.dispose();
  }
}
