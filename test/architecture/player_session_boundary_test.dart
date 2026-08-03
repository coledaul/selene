import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('移动端与桌面端控制层不直接依赖原始 media_kit Player', () {
    for (final path in <String>[
      'lib/ui/player/widgets/mobile_player_controls.dart',
      'lib/ui/player/widgets/pc_player_controls.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('package:media_kit/media_kit.dart')));
      expect(source, isNot(contains('final Player player')));
      expect(source, isNot(contains('widget.player')));
    }
  });

  test('页面会话不向 UI 暴露原始 Player', () {
    final source = File(
      'lib/ui/player/video_playback_session.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('Player get player')));
  });

  test('移动端与桌面端统一使用会话缓存范围和单次 Seek 回调', () {
    for (final path in <String>[
      'lib/ui/player/widgets/mobile_player_controls.dart',
      'lib/ui/player/widgets/pc_player_controls.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('BufferedVideoProgressBar('));
      expect(
        source,
        contains('cachedRanges: widget.playbackState.cachedRanges'),
      );
      expect(source, contains('onSeekRequested: widget.onSeekRequested'));
    }
  });
}
