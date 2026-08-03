import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/ui/player/video_playback_session.dart';
import 'package:selene/ui/player/widgets/playback_problem_presenter.dart';
import 'package:selene/ui/player/widgets/playback_status_overlay.dart';
import 'package:selene/utils/result.dart';

void main() {
  testWidgets('播放完成后发生失败时错误优先且不再显示完成态', (tester) async {
    await tester.pumpWidget(
      _host(
        PlaybackStatusOverlay(
          state: const VideoPlaybackState(
            ready: true,
            completed: true,
            failure: AppFailure(
              kind: FailureKind.platform,
              message: '视频播放发生错误，请重试',
            ),
            failureRetryable: true,
          ),
          live: false,
          isLastEpisode: false,
          onRetry: () async {},
          onDismiss: () {},
          onReplay: () async {},
          onNextEpisode: () {},
        ),
      ),
    );

    expect(find.text('视频播放发生错误，请重试'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(find.text('播放完成'), findsNothing);
    expect(find.text('重新播放'), findsNothing);
  });

  testWidgets('非致命 warning 与完成态同时显示且 warning 位于上层', (tester) async {
    await tester.pumpWidget(
      _host(
        PlaybackStatusOverlay(
          state: const VideoPlaybackState(
            ready: true,
            completed: true,
            warning: AppFailure(
              kind: FailureKind.storage,
              message: '临时缓存已达到上限',
            ),
          ),
          live: false,
          isLastEpisode: true,
          onRetry: () async {},
          onDismiss: () {},
          onReplay: () async {},
        ),
      ),
    );

    expect(find.text('播放完成'), findsOneWidget);
    expect(find.text('临时缓存已达到上限'), findsOneWidget);
    final stack = tester.widget<Stack>(
      find.descendant(
        of: find.byType(PlaybackStatusOverlay),
        matching: find.byType(Stack),
      ),
    );
    expect(stack.children.last, isA<PlaybackProblemPresenter>());
  });
}

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    backgroundColor: Colors.black,
    body: Stack(fit: StackFit.expand, children: [child]),
  ),
);
