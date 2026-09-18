import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:selene/ui/player/widgets/player_detail_actions.dart';

void main() {
  testWidgets('下载和收藏统一为可聚焦的 48 像素按钮，点击分别调用原操作', (tester) async {
    var downloads = 0;
    var favorites = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerDetailActions(
            isFavorite: false,
            onDownload: () => downloads++,
            onToggleFavorite: () => favorites++,
          ),
        ),
      ),
    );
    expect(find.byIcon(LucideIcons.download), findsOneWidget);
    expect(find.byIcon(Icons.download_for_offline_outlined), findsNothing);
    final buttons = find.byType(IconButton);
    expect(buttons, findsNWidgets(2));
    expect(tester.getSize(buttons.at(0)), const Size(48, 48));
    expect(tester.getSize(buttons.at(1)), const Size(48, 48));
    await tester.tap(find.byTooltip('下载视频'));
    await tester.tap(find.byTooltip('收藏'));
    expect(downloads, 1);
    expect(favorites, 1);
  });

  testWidgets('收藏保留红色实心状态及明确的取消语义', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerDetailActions(
            isFavorite: true,
            onDownload: () {},
            onToggleFavorite: () {},
          ),
        ),
      ),
    );
    expect(find.byTooltip('取消收藏'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byType(IconButton).last).isSelected,
      isTrue,
    );
  });

  testWidgets('键盘可以触发下载和收藏操作', (tester) async {
    var downloads = 0;
    var favorites = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerDetailActions(
            isFavorite: false,
            onDownload: () => downloads++,
            onToggleFavorite: () => favorites++,
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(downloads, 1);
    expect(favorites, 1);
  });
}
