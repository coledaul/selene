import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/ui/update/widgets/update_state_cross_fade.dart';

void main() {
  for (final reduceMotion in [false, true]) {
    testWidgets('淡化只暴露当前语义，保留占位 reduceMotion=$reduceMotion', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        Iterable<String> accessibleLabels() => tester.semantics
            .simulatedAccessibilityTraversal()
            .map((node) => node.getSemanticsData().label);
        Widget host(bool second) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: Scaffold(
              body: Center(
                child: UpdateStateCrossFade(
                  showSecond: second,
                  firstChild: const Text('较长的下载状态'),
                  secondChild: const Text('已暂停'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpWidget(host(false));
        final bounds = tester.getRect(find.byType(UpdateStateCrossFade));
        expect(accessibleLabels(), contains('较长的下载状态'));
        expect(accessibleLabels(), isNot(contains('已暂停')));
        // 首次构建直接显示当前状态，不播放入场淡化。
        expect(tester.hasRunningAnimations, isFalse);
        await tester.pumpWidget(host(true));
        expect(accessibleLabels(), isNot(contains('较长的下载状态')));
        expect(accessibleLabels(), contains('已暂停'));
        expect(tester.getRect(find.byType(UpdateStateCrossFade)), bounds);
        if (reduceMotion) {
          expect(find.byType(AnimatedOpacity), findsNothing);
          expect(tester.hasRunningAnimations, isFalse);
        } else {
          expect(tester.hasRunningAnimations, isTrue);
          await tester.pumpAndSettle();
        }
        expect(tester.getRect(find.byType(UpdateStateCrossFade)), bounds);
      } finally {
        semantics.dispose();
      }
    });
  }
}
