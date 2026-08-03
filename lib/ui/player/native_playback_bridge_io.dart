import 'package:media_kit/media_kit.dart';

import 'mpv_property_value.dart';

/// 使用 media_kit 公开的原生播放器 API 访问高级 mpv 属性。
final class NativePlaybackBridge {
  NativePlaybackBridge(Player player) : _player = player;

  final Player _player;

  bool get supported => _player.platform is NativePlayer;

  NativePlayer get _nativePlayer {
    final platform = _player.platform;
    if (platform is! NativePlayer) {
      throw UnsupportedError('当前播放后端不支持原生缓存属性');
    }
    return platform;
  }

  Future<void> setProperty(String property, String value) async {
    await _nativePlayer.setProperty(property, value);
    final actual = await _nativePlayer.getProperty(property);
    if (!mpvPropertyValuesEquivalent(value, actual)) {
      throw StateError('mpv 属性未生效：$property');
    }
  }

  Future<void> observeCacheState(
    Future<void> Function(String value) listener,
  ) => _nativePlayer.observeProperty('demuxer-cache-state', listener);

  Future<String?> readCacheState() async {
    final value = await _nativePlayer.getProperty('demuxer-cache-state');
    return value.isEmpty ? null : value;
  }

  Future<void> unobserveCacheState() =>
      _nativePlayer.unobserveProperty('demuxer-cache-state');
}
