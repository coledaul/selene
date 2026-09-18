import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/ui/core/widgets/windows_title_bar.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('window_manager');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<String> calls;
  late bool maximized;
  Completer<void>? pendingMaximize;
  String? failedMethod;

  setUp(() {
    calls = [];
    maximized = false;
    pendingMaximize = null;
    failedMethod = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == failedMethod) {
        throw PlatformException(code: 'test-failure');
      }
      switch (call.method) {
        case 'isMaximized':
          return maximized;
        case 'maximize':
          if (pendingMaximize != null) await pendingMaximize!.future;
          maximized = true;
        case 'unmaximize':
          maximized = false;
      }
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  for (final dark in [false, true]) {
    testWidgets('保留标题栏尺寸及窗口按钮行为 dark=$dark', (tester) async {
      await _pump(tester, dark: dark);
      expect(tester.getSize(find.byType(WindowsTitleBar)).height, 40);
      expect(tester.getSize(find.byTooltip('关闭')), const Size(46, 40));
      await tester.tap(find.byTooltip('最小化'));
      await tester.pumpAndSettle();
      expect(calls, contains('minimize'));
      await tester.tap(find.byTooltip('最大化'));
      await tester.pumpAndSettle();
      expect(maximized, isTrue);
      expect(find.byTooltip('还原'), findsOneWidget);
      await tester.tap(find.byTooltip('还原'));
      await tester.pumpAndSettle();
      expect(maximized, isFalse);
      await tester.tap(find.byTooltip('关闭'));
      await tester.pumpAndSettle();
      expect(calls, contains('close'));
    });
  }

  testWidgets('拖拽和双击操作系统窗口，按钮区域不触发拖拽', (tester) async {
    await _pump(tester);
    calls.clear();
    final drag = find.byKey(const Key('window-drag-area'));
    await tester.drag(drag, const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(calls.where((call) => call == 'startDragging'), hasLength(1));
    calls.clear();
    await tester.tap(drag);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(drag);
    await tester.pumpAndSettle();
    expect(calls, contains('maximize'));
    calls.clear();
    await tester.tap(find.byTooltip('最小化'));
    await tester.pumpAndSettle();
    expect(calls, ['minimize']);
  });

  testWidgets('系统最大化与还原事件同步按钮，页面释放后移除监听', (tester) async {
    final count = windowManager.listeners.length;
    await _pump(tester);
    expect(windowManager.listeners.length, count + 1);
    for (final listener in windowManager.listeners) {
      listener.onWindowMaximize();
    }
    await tester.pump();
    expect(find.byTooltip('还原'), findsOneWidget);
    for (final listener in windowManager.listeners) {
      listener.onWindowUnmaximize();
    }
    await tester.pump();
    expect(find.byTooltip('最大化'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(windowManager.listeners.length, count);
  });

  testWidgets('快速重复点击不会并发切换，释放后晚返回不更新页面', (tester) async {
    await _pump(tester);
    calls.clear();
    pendingMaximize = Completer<void>();
    await tester.tap(find.byTooltip('最大化'));
    await tester.pump();
    await tester.tap(find.byTooltip('最大化'));
    await tester.pump();
    expect(calls.where((call) => call == 'maximize'), hasLength(1));
    await tester.pumpWidget(const SizedBox());
    pendingMaximize!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('操作失败反馈后仍可重试，支持键盘激活按钮', (tester) async {
    await _pump(tester);
    failedMethod = 'minimize';
    await tester.tap(find.byTooltip('最小化'));
    await tester.pumpAndSettle();
    expect(find.text('窗口操作失败，请重试'), findsOneWidget);
    failedMethod = null;
    calls.clear();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(calls, contains('minimize'));
  });

  testWidgets('主题切换时自绘图标重绘，标题栏不改变高度', (tester) async {
    await _pump(tester);
    final paint = find.descendant(
      of: find.byTooltip('最小化'),
      matching: find.byType(CustomPaint),
    );
    final oldPainter = tester.widget<CustomPaint>(paint).painter!;
    await _pump(tester, dark: true);
    final newPainter = tester.widget<CustomPaint>(paint).painter!;
    expect(newPainter.shouldRepaint(oldPainter), isTrue);
    expect(tester.getSize(find.byType(WindowsTitleBar)).height, 40);
  });
}

Future<void> _pump(WidgetTester tester, {bool dark = false}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
      home: const Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: WindowsTitleBar(title: 'Selene'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
