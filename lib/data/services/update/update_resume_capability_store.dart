import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 仅保存插件实际确认的能力；null 表示没有可靠记录，不能当作支持续传。
abstract interface class UpdateResumeCapabilityStore {
  Future<bool?> read(String taskId, {int retriesRemaining = 0});
  Future<void> write(String taskId, bool supported, {int retriesRemaining = 0});
  Future<void> remove(String taskId);
}

final class SharedPreferencesUpdateResumeCapabilityStore
    implements UpdateResumeCapabilityStore {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  static String _key(String taskId) => 'update_resume_capability_$taskId';

  @override
  Future<bool?> read(String taskId, {int retriesRemaining = 0}) async {
    final value = await _preferences.getString(_key(taskId));
    if (value == null) return null;
    try {
      if (jsonDecode(value) case {
        'supported': final bool supported,
        'retriesRemaining': final int remaining,
      }) {
        return remaining == retriesRemaining ? supported : null;
      }
    } on FormatException {
      // 损坏记录不构成安全暂停的依据。
    }
    return null;
  }

  @override
  Future<void> write(
    String taskId,
    bool supported, {
    int retriesRemaining = 0,
  }) => _preferences.setString(
    _key(taskId),
    jsonEncode({'supported': supported, 'retriesRemaining': retriesRemaining}),
  );

  @override
  Future<void> remove(String taskId) => _preferences.remove(_key(taskId));
}
