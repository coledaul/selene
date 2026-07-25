import 'package:shared_preferences/shared_preferences.dart';

import '../domain/video_download_settings.dart';

abstract interface class DownloadSettingsStore {
  Future<VideoDownloadSettings> load();

  Future<void> save(VideoDownloadSettings settings);
}

class SharedPreferencesDownloadSettingsStore implements DownloadSettingsStore {
  static const _maxConcurrentDownloadsKey =
      'video_download_max_concurrent_downloads';

  @override
  Future<VideoDownloadSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final storedValue = preferences.getInt(_maxConcurrentDownloadsKey);
    if (storedValue == null) {
      return const VideoDownloadSettings();
    }
    return VideoDownloadSettings.normalized(storedValue);
  }

  @override
  Future<void> save(VideoDownloadSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setInt(
      _maxConcurrentDownloadsKey,
      settings.maxConcurrentDownloads,
    );
    if (!saved) {
      throw StateError('下载设置保存失败');
    }
  }
}
