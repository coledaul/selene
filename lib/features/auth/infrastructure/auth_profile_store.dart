import 'package:shared_preferences/shared_preferences.dart';

import '../domain/auth_models.dart';

abstract interface class AuthProfileStore {
  Future<AuthProfile> load();

  Future<void> save(AuthProfile profile);

  Future<void> clearLegacySecrets();
}

abstract interface class AuthPreferences {
  Future<String?> getString(String key);

  Future<bool?> getBool(String key);

  Future<void> setString(String key, String value);

  Future<void> setBool(String key, bool value);

  Future<void> remove(String key);
}

class SharedPreferencesAsyncAdapter implements AuthPreferences {
  SharedPreferencesAsyncAdapter({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool?> getBool(String key) => _preferences.getBool(key);

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<void> remove(String key) => _preferences.remove(key);

  @override
  Future<void> setBool(String key, bool value) =>
      _preferences.setBool(key, value);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);
}

class SharedPreferencesAuthProfileStore implements AuthProfileStore {
  SharedPreferencesAuthProfileStore({AuthPreferences? preferences})
      : _preferences = preferences ?? SharedPreferencesAsyncAdapter();

  static const _serverUrlKey = 'server_url';
  static const _usernameKey = 'username';
  static const _rememberLoginKey = 'auth_remember_login';
  static const _isLocalModeKey = 'is_local_mode';
  static const _legacyPasswordKey = 'password';
  static const _legacyCookiesKey = 'cookies';

  final AuthPreferences _preferences;

  @override
  Future<AuthProfile> load() async {
    final values = await Future.wait<Object?>([
      _preferences.getString(_serverUrlKey),
      _preferences.getString(_usernameKey),
      _preferences.getBool(_rememberLoginKey),
      _preferences.getBool(_isLocalModeKey),
    ]);

    return AuthProfile(
      serverUrl: values[0] as String? ?? '',
      username: values[1] as String? ?? '',
      rememberLogin: values[2] as bool? ?? false,
      isLocalMode: values[3] as bool? ?? false,
    );
  }

  @override
  Future<void> save(AuthProfile profile) async {
    await Future.wait<void>([
      _preferences.setString(_serverUrlKey, profile.serverUrl),
      _preferences.setString(_usernameKey, profile.username),
      _preferences.setBool(_rememberLoginKey, profile.rememberLogin),
      _preferences.setBool(_isLocalModeKey, profile.isLocalMode),
    ]);
  }

  @override
  Future<void> clearLegacySecrets() async {
    await Future.wait<void>([
      _preferences.remove(_legacyPasswordKey),
      _preferences.remove(_legacyCookiesKey),
    ]);
  }
}
