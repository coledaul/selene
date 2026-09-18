import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/ui/core/widgets/fading_tab_view.dart';

void main() {
  testWidgets('首次显示不播放动画，跨页点击只构建当前与目标页', (tester) async {
    final key = GlobalKey<_HarnessState>();
    await tester.pumpWidget(_app(key));
    expect(_opacity(tester), 1);
    expect(key.currentState!.created, {0});

    key.currentState!.select(4);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(_page(tester), 0);
    expect(_opacity(tester), inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();
    expect(_page(tester), 4);
    await tester.pump(const Duration(milliseconds: 70));
    expect(_opacity(tester), inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);
    expect(key.currentState!.created, {0, 4});
    expect(key.currentState!.swipeChanges, isEmpty);
  });

  testWidgets('快速连续选择以最后目标为准，不跳回过期页面', (tester) async {
    final key = GlobalKey<_HarnessState>();
    await tester.pumpWidget(_app(key));
    for (final index in [4, 2, 5]) {
      key.currentState!.select(index);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 25));
    }
    await tester.pumpAndSettle();
    expect(_page(tester), 5);
    expect(_opacity(tester), 1);
    expect(key.currentState!.created, {0, 5});
    expect(key.currentState!.swipeChanges, isEmpty);
  });

  testWidgets('淡出时改回当前页平滑恢复，不执行已取消的跳转', (tester) async {
    final key = GlobalKey<_HarnessState>();
    await tester.pumpWidget(_app(key));
    key.currentState!.select(4);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    final previousOpacity = _opacity(tester);
    key.currentState!.select(0);
    await tester.pump();
    expect(_opacity(tester), previousOpacity);
    await tester.pumpAndSettle();
    expect(_page(tester), 0);
    expect(_opacity(tester), 1);
    expect(key.currentState!.created, {0});
  });

  testWidgets('淡入期间改选不会被旧过渡完成事件覆盖', (tester) async {
    final key = GlobalKey<_HarnessState>();
    await tester.pumpWidget(_app(key));
    key.currentState!.select(4);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump(const Duration(milliseconds: 30));
    expect(_page(tester), 4);
    key.currentState!.select(1);
    await tester.pumpAndSettle();
    expect(_page(tester), 1);
    expect(_opacity(tester), 1);
    expect(key.currentState!.swipeChanges, isEmpty);
  });

  testWidgets('左右手势仍然滑动并同步索引，不触发点击淡出', (tester) async {
    final key = GlobalKey<_HarnessState>();
    await tester.pumpWidget(_app(key));
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(_page(tester), 1);
    expect(_opacity(tester), 1);
    expect(key.currentState!.index, 1);
    expect(key.currentState!.swipeChanges, [1]);
  });

  testWidgets('手势可接管淡出，旧点击目标不再生效', (tester) async {
    final key = GlobalKey<_HarnessState>();
    await tester.pumpWidget(_app(key));
    key.currentState!.select(4);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(_page(tester), 1);
    expect(key.currentState!.index, 1);
    expect(_opacity(tester), 1);
    expect(key.currentState!.created, isNot(contains(4)));
  });

  testWidgets('点击可以终止手势惯性并稳定到最后目标', (tester) async {
    final key = GlobalKey<_HarnessState>();
    await tester.pumpWidget(_app(key));
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 800);
    await tester.pump(const Duration(milliseconds: 16));
    key.currentState!.select(4);
    await tester.pump();
    final frozenPage = _page(tester);
    await tester.pump(const Duration(milliseconds: 30));
    expect(_page(tester), frozenPage);
    await tester.pumpAndSettle();
    expect(_page(tester), 4);
    expect(key.currentState!.index, 4);
    expect(_opacity(tester), 1);
  });

  testWidgets('减少动画时直接切换，中途开启也立即稳定到目标页', (tester) async {
    final key = GlobalKey<_HarnessState>();
    await tester.pumpWidget(_app(key));
    key.currentState!
      ..setReducedMotion(true)
      ..select(4);
    await tester.pump();
    await tester.pump();
    expect(_page(tester), 4);
    expect(_opacity(tester), 1);
    key.currentState!.setReducedMotion(false);
    await tester.pump();
    key.currentState!.select(2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    key.currentState!.setReducedMotion(true);
    await tester.pump();
    await tester.pump();
    expect(_page(tester), 2);
    expect(_opacity(tester), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('保活页面的状态不会因淡入淡出重新创建', (tester) async {
    final key = GlobalKey<_HarnessState>();
    await tester.pumpWidget(_app(key));
    await tester.tap(find.text('page-0:0'));
    await tester.pump();
    key.currentState!.select(4);
    await tester.pumpAndSettle();
    key.currentState!.select(0);
    await tester.pumpAndSettle();
    expect(find.text('page-0:1'), findsOneWidget);
    expect(key.currentState!.created, {0, 4});
  });

  testWidgets('过渡中销毁后不留下延迟跳转或动画异常', (tester) async {
    final key = GlobalKey<_HarnessState>();
    await tester.pumpWidget(_app(key));
    key.currentState!.select(4);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('手机尺寸横竖屏变化不打断目标切换或造成溢出', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey<_HarnessState>();
    await tester.pumpWidget(_app(key));
    key.currentState!.select(4);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpAndSettle();
    expect(_page(tester), 4);
    expect(_opacity(tester), 1);
    tester.view.physicalSize = const Size(390, 844);
    key.currentState!.select(0);
    await tester.pumpAndSettle();
    expect(_page(tester), 0);
    expect(_opacity(tester), 1);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(GlobalKey<_HarnessState> key) => MaterialApp(
  home: Scaffold(body: _Harness(key: key)),
);

double _page(WidgetTester tester) =>
    tester.widget<PageView>(find.byType(PageView)).controller!.page!;
double _opacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find
          .descendant(
            of: find.byType(FadingTabView),
            matching: find.byType(FadeTransition),
          )
          .first,
    )
    .opacity
    .value;

class _Harness extends StatefulWidget {
  const _Harness({super.key});

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  int index = 0;
  bool reducedMotion = false;
  final created = <int>{};
  final swipeChanges = <int>[];

  void select(int value) => setState(() => index = value);
  void setReducedMotion(bool value) => setState(() => reducedMotion = value);

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
    child: FadingTabView(
      index: index,
      onIndexChanged: (value) {
        swipeChanges.add(value);
        select(value);
      },
      children: List.generate(
        6,
        (index) => _Page(index: index, onCreate: () => created.add(index)),
      ),
    ),
  );
}

class _Page extends StatefulWidget {
  const _Page({required this.index, required this.onCreate});

  final int index;
  final VoidCallback onCreate;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> with AutomaticKeepAliveClientMixin {
  int count = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.onCreate();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ColoredBox(
      color: Colors.primaries[widget.index],
      child: Center(
        child: TextButton(
          onPressed: () => setState(() => count++),
          child: Text('page-${widget.index}:$count'),
        ),
      ),
    );
  }
}
