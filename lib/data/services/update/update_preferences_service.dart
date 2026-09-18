import 'package:shared_preferences/shared_preferences.dart';

abstract interface class UpdatePreferencesService {
  Future<bool> shouldPrompt(String version);
  Future<void> dismiss(String version);
}

final class SharedPreferencesUpdateService implements UpdatePreferencesService {
  static const String _dismissedVersionKey = 'dismissed_version';

  @override
  Future<bool> shouldPrompt(String version) async =>
      await SharedPreferencesAsync().getString(_dismissedVersionKey) != version;

  @override
  Future<void> dismiss(String version) {
    return SharedPreferencesAsync().setString(_dismissedVersionKey, version);
  }
}
