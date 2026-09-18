import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class CredentialStore {
  Future<String?> readPassword();

  Future<void> writePassword(String password);

  Future<void> deletePassword();
}

class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(migrateWithBackup: true),
            // 独立分发的 macOS App 使用系统登录钥匙串，不依赖共享访问组签名。
            // 仍由系统加密保存；只影响 macOS，不能改为普通本地配置兜底。
            mOptions: MacOsOptions(usesDataProtectionKeychain: false),
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
