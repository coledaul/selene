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

  test('普通播放页使用不可拆分的地址和媒体类型打开新源', () {
    final widgetSource = File(
      'lib/ui/player/widgets/video_player_widget.dart',
    ).readAsStringSync();
    expect(
      widgetSource,
      contains(
        'Future<AppFailure?> updateDataSource(\n    PlaybackMediaSource media',
      ),
    );
    expect(widgetSource, contains('kind: media.kind'));

    final screenSource = File(
      'lib/ui/player/widgets/player_screen.dart',
    ).readAsStringSync();
    expect(
      screenSource,
      contains('final playbackMedia = resolved.valueOrNull!'),
    );
    expect(
      screenSource,
      contains('controller.updateDataSource(\n          playbackMedia'),
    );
    expect(screenSource, contains('allowCompletedDownload: !targetIsCasting'));
  });

  test('投屏地址由页面按需解析且控制层不复用本地播放地址', () {
    final widgetSource = File(
      'lib/ui/player/widgets/video_player_widget.dart',
    ).readAsStringSync();
    expect(
      widgetSource,
      contains('widget.onCastUrlRequested ?? _currentMediaUrl'),
    );
    expect(widgetSource, contains('playbackState.mediaKind !='));
    expect(widgetSource, contains('PlaybackMediaKind.localFile'));
    expect(widgetSource, isNot(contains('videoUrl: _session.currentUrl')));

    for (final path in <String>[
      'lib/ui/player/widgets/mobile_player_controls.dart',
      'lib/ui/player/widgets/pc_player_controls.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('final castUrl = await widget.onCastUrlRequested()'),
      );
      expect(source, contains('currentUrl: castUrl'));
      expect(source, isNot(contains('currentUrl: widget.videoUrl')));
    }

    final screenSource = File(
      'lib/ui/player/widgets/player_screen.dart',
    ).readAsStringSync();
    expect(screenSource, contains('onCastUrlRequested: _resolveRemoteCastUrl'));
    expect(screenSource, contains('allowCompletedDownload: false'));
  });
}
