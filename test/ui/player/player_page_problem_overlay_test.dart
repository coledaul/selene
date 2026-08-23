import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/ui/player/widgets/player_page_problem_overlay.dart';

void main() {
  testWidgets('重新尝试执行问题携带的重试动作且运行期间禁用按钮', (tester) async {
    var retryCount = 0;
    final retryGate = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: PlayerPageProblemOverlay(
          problem: PlayerPageProblem(
            message: '播放地址解析失败',
            retry: () async {
              retryCount++;
              await retryGate.future;
            },
          ),
          onBackPressed: () {},
        ),
      ),
    );

    await tester.tap(find.text('重新尝试'));
    await tester.pump();

    expect(retryCount, 1);
    expect(find.text('正在重试...'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, '正在重试...'),
          )
          .onPressed,
      isNull,
    );

    retryGate.complete();
    await tester.pump();
  });

  testWidgets('没有恢复动作的问题不显示重新尝试', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PlayerPageProblemOverlay(
          problem: const PlayerPageProblem(message: '当前剧集没有可用地址'),
          onBackPressed: () {},
        ),
      ),
    );

    expect(find.text('当前剧集没有可用地址'), findsOneWidget);
    expect(find.text('重新尝试'), findsNothing);
  });
}
