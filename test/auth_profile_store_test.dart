import 'package:flutter_test/flutter_test.dart';
import 'package:selene/domain/models/auth_models.dart';
import 'package:selene/data/services/auth_profile_service.dart';

void main() {
  test('连接资料与运行模式可保存，密码和 Cookie 键会被清除', () async {
    final preferences = _MemoryPreferences(<String, Object>{
      'password': 'legacy-secret',
      'cookies': 'auth=legacy',
    });
    final store = SharedPreferencesAuthProfileStore(preferences: preferences);

    await store.save(
      const AuthProfile(
        serverUrl: 'https://example.com',
        username: 'alice',
        rememberLogin: true,
        isLocalMode: false,
      ),
    );
    await store.clearLegacySecrets();

    expect(
      await store.load(),
      isA<AuthProfile>()
          .having(
            (value) => value.serverUrl,
            'serverUrl',
            'https://example.com',
          )
          .having((value) => value.username, 'username', 'alice')
          .having((value) => value.rememberLogin, 'rememberLogin', isTrue),
    );
    expect(preferences.values.containsKey('password'), isFalse);
    expect(preferences.values.containsKey('cookies'), isFalse);
  });
}

class _MemoryPreferences implements AuthPreferences {
  _MemoryPreferences(this.values);

  final Map<String, Object> values;

  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;

  @override
  Future<String?> getString(String key) async => values[key] as String?;

  @override
  Future<void> remove(String key) async => values.remove(key);

  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;

  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}
