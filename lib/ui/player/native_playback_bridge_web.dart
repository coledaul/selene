import 'package:media_kit/media_kit.dart';

/// Web 不使用 mpv 属性；后续应由 HTMLMediaElement.buffered 单独实现。
final class NativePlaybackBridge {
  NativePlaybackBridge(Player player);

  bool get supported => false;

  Future<void> setProperty(String property, String value) async {}

  Future<void> observeCacheState(
    Future<void> Function(String value) listener,
  ) async {}

  Future<String?> readCacheState() async => null;

  Future<void> unobserveCacheState() async {}
}
