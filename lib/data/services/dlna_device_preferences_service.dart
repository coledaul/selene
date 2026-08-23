import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/dlna_device.dart';

abstract interface class DlnaDevicePreferencesService {
  Future<RecentDlnaDevice?> loadRecent();
  Future<void> saveRecent(RecentDlnaDevice device);
}

final class SharedPreferencesDlnaDeviceService
    implements DlnaDevicePreferencesService {
  static const String _recentDeviceKey = 'dlna_recent_device_v1';

  @override
  Future<RecentDlnaDevice?> loadRecent() async {
    final value = await SharedPreferencesAsync().getString(_recentDeviceKey);
    if (value == null || value.isEmpty) return null;
    try {
      return RecentDlnaDevice.tryFromJson(jsonDecode(value));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> saveRecent(RecentDlnaDevice device) => SharedPreferencesAsync()
      .setString(_recentDeviceKey, jsonEncode(device.toJson()));
}
