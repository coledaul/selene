import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:selene/ui/core/widgets/app_back_button.dart';
import 'package:selene/ui/core/widgets/app_page_bar.dart';

void main() {
  testWidgets('公共页面标题统一显示业务图标、标题和操作区', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: AppPageBar(
            title: '下载管理',
            titleIcon: LucideIcons.download,
            actions: <Widget>[
              IconButton(onPressed: null, icon: Icon(Icons.settings_outlined)),
            ],
          ),
        ),
      ),
    );

    expect(find.text('下载管理'), findsOneWidget);
    expect(find.byIcon(LucideIcons.download), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byType(AppBackButton), findsNothing);
  });

  testWidgets('公共页面标题在可返回路由中显示统一返回按钮', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(
                  appBar: AppPageBar(title: '二级页面'),
                  body: Text('二级内容'),
                ),
              ),
            ),
            child: const Text('打开'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.byType(AppBackButton), findsOneWidget);

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text('打开'), findsOneWidget);
  });
}
