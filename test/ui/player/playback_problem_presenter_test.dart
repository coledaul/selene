import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/ui/player/video_playback_session.dart';
import 'package:selene/ui/player/widgets/playback_problem_presenter.dart';
import 'package:selene/utils/result.dart';

void main() {
  testWidgets('ready 后失败仍显示明确消息与重试入口', (tester) async {
    var retryCount = 0;
    await tester.pumpWidget(
      _host(
        PlaybackProblemPresenter(
          state: const VideoPlaybackState(
            ready: true,
            failure: AppFailure(
              kind: FailureKind.platform,
              message: '视频播放发生错误，请重试',
            ),
            failureRetryable: true,
          ),
          onRetry: () async => retryCount++,
          onDismiss: () {},
        ),
      ),
    );

    expect(find.text('视频播放发生错误，请重试'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pump();
    expect(retryCount, 1);
  });

  testWidgets('非致命缓存降级使用轻量提示且不显示重试', (tester) async {
    await tester.pumpWidget(
      _host(
        PlaybackProblemPresenter(
          state: const VideoPlaybackState(
            ready: true,
            warning: AppFailure(
              kind: FailureKind.platform,
              message: '无法读取缓存范围，播放将继续',
            ),
          ),
          onRetry: () async {},
          onDismiss: () {},
        ),
      ),
    );

    expect(find.text('无法读取缓存范围，播放将继续'), findsOneWidget);
    expect(find.text('重试'), findsNothing);
  });

  testWidgets('媒体尚未 ready 的打开失败使用阻断错误层', (tester) async {
    await tester.pumpWidget(
      _host(
        PlaybackProblemPresenter(
          state: const VideoPlaybackState(
            failure: AppFailure(
              kind: FailureKind.platform,
              message: '视频打开失败，请重试',
            ),
            failureRetryable: true,
          ),
          onRetry: () async {},
          onDismiss: () {},
        ),
      ),
    );

    expect(find.text('视频打开失败，请重试'), findsOneWidget);
    expect(find.byType(ColoredBox), findsWidgets);
  });
}

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    backgroundColor: Colors.black,
    body: Stack(fit: StackFit.expand, children: [child]),
  ),
);
