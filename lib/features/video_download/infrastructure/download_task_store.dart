import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/video_download_task.dart';

abstract interface class DownloadTaskStore {
  Future<List<VideoDownloadTask>> load();

  Future<void> save(List<VideoDownloadTask> tasks);
}

class SharedPreferencesDownloadTaskStore implements DownloadTaskStore {
  static const _storageKey = 'video_download_tasks_v1';

  @override
  Future<List<VideoDownloadTask>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final rawValue = preferences.getString(_storageKey);
    if (rawValue == null || rawValue.isEmpty) {
      return <VideoDownloadTask>[];
    }

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! List) {
        return <VideoDownloadTask>[];
      }
      final tasks = <VideoDownloadTask>[];
      for (final item in decoded.whereType<Map>()) {
        try {
          tasks.add(
            VideoDownloadTask.fromJson(Map<String, dynamic>.from(item)),
          );
        } on FormatException {
          // 跳过单条损坏记录，保留其余可恢复任务。
        } on TypeError {
          // 跳过字段类型不兼容的旧记录。
        }
      }
      return tasks;
    } on FormatException {
      return <VideoDownloadTask>[];
    }
  }

  @override
  Future<void> save(List<VideoDownloadTask> tasks) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      tasks.map((task) => task.toJson()).toList(growable: false),
    );
    final saved = await preferences.setString(_storageKey, encoded);
    if (!saved) {
      throw StateError('下载任务保存失败');
    }
  }
}
