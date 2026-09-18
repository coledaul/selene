import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/app/windows_window_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const windowChannel = MethodChannel('window_manager');
  const screenChannel = MethodChannel(
    'dev.leanflutter.plugins/screen_retriever',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  const display = {
    'id': 'test-display',
    'size': {'width': 1920.0, 'height': 1080.0},
    'visibleSize': {'width': 1920.0, 'height': 1040.0},
    'visiblePosition': {'dx': 0.0, 'dy': 0.0},
  };

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(windowChannel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'isFullScreen' || 'isMaximized' || 'isMinimized' => false,
        'getBounds' => {'x': 0.0, 'y': 0.0, 'width': 1024.0, 'height': 600.0},
        _ => null,
      };
    });
    messenger.setMockMethodCallHandler(
      screenChannel,
      (call) async => switch (call.method) {
        'getPrimaryDisplay' => display,
        'getAllDisplays' => {
          'displays': [display],
        },
        'getCursorScreenPoint' => {'dx': 200.0, 'dy': 200.0},
        _ => null,
      },
    );
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(windowChannel, null);
    messenger.setMockMethodCallHandler(screenChannel, null);
  });

  test('首帧前配置自定义标题栏、初始及最小尺寸和居中，不提前显示窗口', () async {
    await configureWindowsWindow();
    expect(calls.first.method, 'ensureInitialized');
    final titleBar = calls.singleWhere(
      (call) => call.method == 'setTitleBarStyle',
    );
    expect(titleBar.arguments, containsPair('titleBarStyle', 'hidden'));
    expect(titleBar.arguments, containsPair('windowButtonVisibility', false));
    expect(
      calls.singleWhere((call) => call.method == 'setMinimumSize').arguments,
      containsPair('width', 1024.0),
    );
    expect(
      calls.singleWhere((call) => call.method == 'setMinimumSize').arguments,
      containsPair('height', 600.0),
    );
    final bounds = calls.where((call) => call.method == 'setBounds').toList();
    expect(bounds.first.arguments, containsPair('width', 1024.0));
    expect(bounds.first.arguments, containsPair('height', 600.0));
    expect(bounds.last.arguments, containsPair('x', 448.0));
    expect(bounds.last.arguments, containsPair('y', 220.0));
    expect(
      calls.singleWhere((call) => call.method == 'setTitle').arguments,
      containsPair('title', 'Selene'),
    );
    expect(calls.any((call) => call.method == 'show'), isFalse);
  });

  test('窗口初始化失败显式返回，不把失败当作配置成功', () async {
    messenger.setMockMethodCallHandler(
      windowChannel,
      (_) async => throw PlatformException(code: 'unavailable'),
    );
    await expectLater(
      configureWindowsWindow(),
      throwsA(isA<PlatformException>()),
    );
  });
}
