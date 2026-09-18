import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/services/credential_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  String? saved;

  setUp(() {
    calls = [];
    saved = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      final args = Map<String, dynamic>.from(call.arguments as Map);
      switch (call.method) {
        case 'write':
          saved = args['value'] as String;
          return null;
        case 'read':
          return saved;
        case 'delete':
          saved = null;
          return null;
        default:
          throw StateError('未预期的安全存储操作');
      }
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  for (final platform in [
    TargetPlatform.macOS,
    TargetPlatform.iOS,
    TargetPlatform.android,
    TargetPlatform.windows,
    TargetPlatform.linux,
  ]) {
    test('$platform 的密码读写删除沿用同一安全存储配置', () async {
      debugDefaultTargetPlatformOverride = platform;
      final store = SecureCredentialStore();
      await store.deletePassword();
      await store.writePassword('test-only-password');
      expect(await store.readPassword(), 'test-only-password');
      await store.deletePassword();
      await store.deletePassword();
      expect(await store.readPassword(), isNull);
      final options = calls
          .map(
            (call) => Map<String, dynamic>.from(
              (call.arguments as Map)['options'] as Map,
            ),
          )
          .toList();
      for (final entry in options) {
        expect(entry, options.first);
        if (platform == TargetPlatform.macOS) {
          expect(entry['usesDataProtectionKeychain'], 'false');
          expect(entry['synchronizable'], 'false');
        } else {
          expect(entry.containsKey('usesDataProtectionKeychain'), isFalse);
        }
        if (platform == TargetPlatform.android) {
          expect(entry['migrateWithBackup'], 'true');
        }
        if (platform == TargetPlatform.iOS) {
          expect(entry['accessibility'], 'unlocked');
          expect(entry['synchronizable'], 'false');
        }
      }
      expect(
        calls.every(
          (call) => (call.arguments as Map)['key'] == 'auth_password',
        ),
        isTrue,
      );
    });
  }

  test('写入后必须读回确认，保存未生效不能伪造成功', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);
    await expectLater(
      SecureCredentialStore().writePassword('test-only-password'),
      throwsStateError,
    );
  });

  for (final method in ['read', 'write', 'delete']) {
    test('$method 失败显式向上传递，不退回普通本地存储', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'test-unavailable');
      });
      final store = SecureCredentialStore();
      final operation = switch (method) {
        'read' => store.readPassword(),
        'write' => store.writePassword('test-only-password'),
        _ => store.deletePassword(),
      };
      await expectLater(operation, throwsA(isA<PlatformException>()));
    });
  }
}
