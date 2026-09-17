import 'dart:convert';

/// Android 默认 gpu 输出的首帧确认，不使用 media_kit 的合并 buffering 流。
///
/// vo-passes/fresh 由 GPU 绘制新视频帧后产生；core-idle/seeking 确认
/// 启动或跳转完成。直接回读避免覆写 SDK 已注册的原生属性观察者。
final class NativeVideoFrameProbe {
  const NativeVideoFrameProbe(this._readProperty);

  final Future<String> Function(String name) _readProperty;

  Future<bool> hasRenderedFrame() async {
    if (await _readProperty('current-vo') != 'gpu') return false;
    final passes = await _readProperty('vo-passes');
    // 输出尚未创建时 mpv 会返回空值，这是等待态而非成功。
    if (passes.isEmpty) return false;
    final decoded = jsonDecode(passes);
    if (decoded is! Map || decoded['fresh'] is! List) {
      throw const FormatException('无效的视频输出状态');
    }
    if ((decoded['fresh'] as List).isEmpty) return false;
    return await _readProperty('core-idle') == 'no' &&
        await _readProperty('seeking') == 'no';
  }
}
