import 'package:shared_preferences/shared_preferences.dart';

abstract interface class UpdatePreferencesService {
  Future<bool> shouldPrompt(String version, DateTime now);
  Future<void> dismiss(String version);
}

final class SharedPreferencesUpdateService implements UpdatePreferencesService {
  static const String _lastCheckKey = 'last_version_check';
  static const String _dismissedVersionKey = 'dismissed_version';

  @override
  Future<bool> shouldPrompt(String version, DateTime now) async {
    final preferences = SharedPreferencesAsync();
    if (await preferences.getString(_dismissedVersionKey) == version) {
      return false;
    }
    final lastCheck = await preferences.getInt(_lastCheckKey) ?? 0;
    if (now.millisecondsSinceEpoch - lastCheck <
        const Duration(days: 1).inMilliseconds) {
      return false;
    }
    await preferences.setInt(_lastCheckKey, now.millisecondsSinceEpoch);
    return true;
  }

  @override
  Future<void> dismiss(String version) {
    return SharedPreferencesAsync().setString(_dismissedVersionKey, version);
  }
}
