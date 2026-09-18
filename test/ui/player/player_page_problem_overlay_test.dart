import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/ui/player/widgets/player_page_problem_overlay.dart';
import 'package:selene/ui/core/themes/app_theme.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('重试加载沿用当前配色，不被全局禁用背景覆盖 dark=$dark', (tester) async {
      final gate = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: PlayerPageProblemOverlay(
            problem: PlayerPageProblem(
              message: '失败',
              retry: () async {
                calls++;
                await gate.future;
              },
            ),
            onBackPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      Material surface() => tester.widget<Material>(
        find
            .descendant(
              of: find.byType(ElevatedButton).last,
              matching: find.byType(Material),
            )
            .first,
      );
      final before = surface().color;
      await tester.tap(find.text('重新尝试'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(surface().color, before);
      await tester.tap(find.text('正在重试...'));
      expect(calls, 1);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('重新尝试'), findsOneWidget);
      expect(surface().color, before);
    });
  }
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
