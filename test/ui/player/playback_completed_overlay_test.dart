import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/ui/player/widgets/playback_completed_overlay.dart';

void main() {
  testWidgets('非最后一集完成态显示重新播放和下一集', (tester) async {
    var replayCount = 0;
    var nextCount = 0;
    await tester.pumpWidget(
      _host(
        PlaybackCompletedOverlay(
          isLastEpisode: false,
          onReplay: () async => replayCount++,
          onNextEpisode: () => nextCount++,
        ),
      ),
    );

    expect(find.text('重新播放'), findsOneWidget);
    expect(find.text('下一集'), findsOneWidget);
    await tester.tap(find.text('重新播放'));
    await tester.pump();
    await tester.tap(find.text('下一集'));

    expect(replayCount, 1);
    expect(nextCount, 1);
  });

  testWidgets('最后一集或没有下一集回调时不显示下一集', (tester) async {
    await tester.pumpWidget(
      _host(
        PlaybackCompletedOverlay(isLastEpisode: true, onReplay: () async {}),
      ),
    );

    expect(find.text('重新播放'), findsOneWidget);
    expect(find.text('下一集'), findsNothing);
  });

  test('页面完成回调不再直接调用 startPlay 自动切集', () {
    final source = File(
      'lib/ui/player/widgets/player_screen.dart',
    ).readAsStringSync();
    final start = source.indexOf('void _onVideoCompleted()');
    final end = source.indexOf('  /// 显示Toast消息', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    expect(source.substring(start, end), isNot(contains('startPlay(')));
  });

  test('逐媒体播放会话只由创建它的 VideoPlayerWidget State 释放', () {
    final widgetSource = File(
      'lib/ui/player/widgets/video_player_widget.dart',
    ).readAsStringSync();
    final controllerStart = widgetSource.indexOf(
      'class VideoPlayerWidgetController',
    );
    final stateStart = widgetSource.indexOf(
      'class _VideoPlayerWidgetState',
      controllerStart,
    );
    expect(controllerStart, greaterThanOrEqualTo(0));
    expect(stateStart, greaterThan(controllerStart));
    expect(
      widgetSource.substring(controllerStart, stateStart),
      isNot(contains('dispose()')),
    );

    final screenSource = File(
      'lib/ui/player/widgets/player_screen.dart',
    ).readAsStringSync();
    expect(screenSource, isNot(contains('_videoPlayerController?.dispose()')));
    expect(widgetSource, contains('await oldSession.disposeSession();'));
    expect(
      widgetSource,
      contains('unawaited(queued.then((_) => _session.disposeSession()))'),
    );
  });

  test('点播续播位置直接传入新媒体 open 且不保留 ready 后二次 Seek', () {
    final source = File(
      'lib/ui/player/widgets/player_screen.dart',
    ).readAsStringSync();
    final start = source.indexOf('void startPlay(');
    final end = source.indexOf('  void setInfosByDetail', start);
    final startPlaySource = source.substring(start, end);

    expect(startPlaySource, contains('startAt: startAt'));
    expect(source, isNot(contains('_resumeStartAt')));
  });

  test('换源解析失败可重试，播放器失败只退出外层蒙版并保留会话错误', () {
    final source = File(
      'lib/ui/player/widgets/player_screen.dart',
    ).readAsStringSync();
    final updateStart = source.indexOf('Future<void> updateVideoUrl');
    final updateEnd = source.indexOf(
      'Future<void> _showDownloadSelector',
      updateStart,
    );
    final updateSource = source.substring(updateStart, updateEnd);

    expect(
      updateSource,
      contains('_showPageProblem(\n          resolved.failureOrNull?.message'),
    );
    expect(updateSource, contains('await controller.updateDataSource('));
    expect(updateSource, isNot(contains('final failure = await controller')));
    expect(updateSource, isNot(contains('_showPageProblem(failure.message)')));
    expect(updateSource, contains('_retryPlaybackUrl(newUrl, startAt)'));
    expect(
      updateSource,
      contains('sourceGeneration != _playbackSourceGeneration'),
    );
    expect(updateSource, isNot(contains('静默处理错误')));
    expect(source, contains('retry: _retryInitialLoad'));
    expect(source, isNot(contains('onPressed: hideError')));

    final showErrorStart = source.indexOf('void _showPageProblem(');
    final showErrorEnd = source.indexOf(
      'Future<void> _retryInitialLoad()',
      showErrorStart,
    );
    final showErrorSource = source.substring(showErrorStart, showErrorEnd);
    expect(showErrorSource, contains('_showSwitchLoadingOverlay = false'));
  });
}

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    backgroundColor: Colors.black,
    body: Center(child: child),
  ),
);
