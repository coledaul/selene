import 'dart:io' show Platform;

import 'package:macos_window_utils/macos_window_utils.dart';

abstract interface class WindowAppearanceService {
  Future<void> apply({required bool dark});
}

final class MacOsWindowAppearanceService implements WindowAppearanceService {
  @override
  Future<void> apply({required bool dark}) async {
    if (!Platform.isMacOS) {
      return;
    }
    await WindowManipulator.overrideMacOSBrightness(dark: dark);
  }
}
