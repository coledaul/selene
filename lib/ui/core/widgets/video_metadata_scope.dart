import 'package:flutter/widgets.dart';

import '../view_models/video_metadata_view_model.dart';

class VideoMetadataScope extends InheritedWidget {
  const VideoMetadataScope({
    super.key,
    required this.create,
    required super.child,
  });

  final VideoMetadataViewModel Function() create;

  static VideoMetadataViewModel createViewModel(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<VideoMetadataScope>();
    assert(scope != null, 'VideoMetadataScope 未安装到应用组合根');
    return scope!.create();
  }

  @override
  bool updateShouldNotify(VideoMetadataScope oldWidget) =>
      create != oldWidget.create;
}
