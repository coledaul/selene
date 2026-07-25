import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class CredentialStore {
  Future<String?> readPassword();

  Future<void> writePassword(String password);

  Future<void> deletePassword();
}

class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(migrateWithBackup: true),
            );

  static const _passwordKey = 'auth_password';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readPassword() => _storage.read(key: _passwordKey);

  @override
  Future<void> writePassword(String password) async {
    await _storage.write(key: _passwordKey, value: password);
    final stored = await _storage.read(key: _passwordKey);
    if (stored != password) {
      throw StateError('安全存储写入校验失败');
    }
  }

  @override
  Future<void> deletePassword() => _storage.delete(key: _passwordKey);
}
