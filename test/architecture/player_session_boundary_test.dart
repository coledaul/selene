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
    expect(source, isNot(contains('retryCurrent()')));
  });

  test('每次换源和重试都释放旧会话并创建新首帧生命周期', () {
    final source = File(
      'lib/ui/player/widgets/video_player_widget.dart',
    ).readAsStringSync();
    expect(source, contains('await oldSession.disposeSession();'));
    expect(source, contains('final nextSession = _createSession();'));
    expect(source, contains('final openOperation = nextSession.open('));
    expect(source, contains('onRetry: _retryCurrentMedia'));
    expect(source, isNot(contains('onRetry: _session.retryCurrent')));
  });

  test('播放器失败由会话呈现，页面与直播页只负责退出外层加载蒙版', () {
    final widgetSource = File(
      'lib/ui/player/widgets/video_player_widget.dart',
    ).readAsStringSync();
    expect(widgetSource, contains('widget.onFailure?.call(next.failure!)'));

    for (final path in <String>[
      'lib/ui/player/widgets/player_screen.dart',
      'lib/ui/live/widgets/live_player_screen.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('onFailure: _onVideoPlayerFailure'));
    }
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
      contains('Future<void> updateDataSource(\n    PlaybackMediaSource media'),
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
      contains(
        'await controller.updateDataSource(playbackMedia, startAt: startAt);',
      ),
    );
    expect(screenSource, contains('allowCompletedDownload: !targetIsCasting'));
  });

  test('投屏请求由播放器宿主统一协调且移动桌面控制层不直接创建对话框', () {
    final widgetSource = File(
      'lib/ui/player/widgets/video_player_widget.dart',
    ).readAsStringSync();
    expect(widgetSource, contains('widget.onCastRequested'));
    expect(widgetSource, contains('canCast: widget.onCastRequested != null'));
    expect(widgetSource, isNot(contains('videoUrl: _session.currentUrl')));

    for (final path in <String>[
      'lib/ui/player/widgets/mobile_player_controls.dart',
      'lib/ui/player/widgets/pc_player_controls.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('await widget.onCastRequested()'));
      expect(source, isNot(contains("import 'dlna_device_dialog.dart'")));
      expect(source, isNot(contains('DLNADeviceDialog(')));
      expect(source, isNot(contains('onCastUrlRequested')));
    }

    final screenSource = File(
      'lib/ui/player/widgets/player_screen.dart',
    ).readAsStringSync();
    expect(screenSource, contains('onCastRequested: _showDlnaDeviceDialog'));
    expect(screenSource, contains('allowCompletedDownload: false'));

    final serviceSource = File(
      'lib/data/services/dlna_playback_service.dart',
    ).readAsStringSync();
    expect(
      serviceSource,
      contains('await device.setUrl(mediaUrl, title: title)'),
    );
    expect(serviceSource, contains('await device.play()'));
  });

  test('DLNA Widget 只渲染领域快照，不依赖设备 SDK 或执行外部 I/O', () {
    for (final path in <String>[
      'lib/ui/player/widgets/dlna_device_dialog.dart',
      'lib/ui/player/widgets/dlna_player.dart',
      'lib/ui/player/widgets/dlna_player_controls.dart',
      'lib/ui/player/widgets/player_screen.dart',
      'lib/ui/live/widgets/live_player_screen.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('package:dlna_dart/')), reason: path);
    }

    final playerSource = File(
      'lib/ui/player/widgets/dlna_player.dart',
    ).readAsStringSync();
    for (final forbidden in <String>[
      '.position()',
      '.getTransportInfo()',
      'PositionParser(',
      'TransportInfoParser(',
      'Timer.periodic(',
    ]) {
      expect(playerSource, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  test('DLNA 发现会话由页面 ViewModel 独立拥有', () {
    final dependenciesSource = File(
      'lib/app/app_dependencies.dart',
    ).readAsStringSync();
    expect(
      dependenciesSource,
      contains('DlnaDeviceRepository createDlnaDeviceRepository()'),
    );
    expect(
      dependenciesSource,
      isNot(contains('final DlnaDeviceRepository dlnaDeviceRepository;')),
    );

    final routesSource = File('lib/routing/routes.dart').readAsStringSync();
    expect(routesSource, contains('dependencies.createDlnaDeviceRepository()'));
  });
}
