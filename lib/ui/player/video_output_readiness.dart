import 'dart:ui';

/// 纹理可用条件，不代表平台已经将视频帧呈现到屏幕。
bool isVideoOutputUsable({
  required int? textureId,
  required Rect? textureRect,
  required int? videoWidth,
  required int? videoHeight,
}) {
  if (textureId == null ||
      textureId < 0 ||
      textureRect == null ||
      (videoWidth ?? 0) <= 0 ||
      (videoHeight ?? 0) <= 0) {
    return false;
  }
  final width = textureRect.width;
  final height = textureRect.height;
  if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
    return false;
  }
  // media_kit 用 1×1 占位纹理启动原生渲染，不能把它当作视频就绪。
  return width > 1 || height > 1;
}
