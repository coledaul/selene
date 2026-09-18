import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/download_repository.dart';
import 'package:selene/domain/models/search_result.dart';
import 'package:selene/domain/models/video_download_task.dart';
import 'package:selene/ui/core/themes/app_theme.dart';
import 'package:selene/ui/downloads/view_models/download_view_model.dart';
import 'package:selene/ui/downloads/widgets/download_selection_sheet.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('创建下载时保持配色、清晰进度和防重复，失败恢复 dark=$dark', (tester) async {
      final repository = _Repository();
      final viewModel = DownloadViewModel(repository: repository);
      addTearDown(viewModel.dispose);
      addTearDown(repository.dispose);
      final theme = dark ? AppTheme.dark : AppTheme.light;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDownloadSelectionSheet(
                  context: context,
                  detail: SearchResult(
                    id: '1',
                    title: '测试',
                    poster: '',
                    episodes: ['https://example.com/video'],
                    episodesTitles: ['第一集'],
                    source: 'test',
                    sourceName: '测试源',
                    year: '',
                  ),
                  currentEpisodeIndex: 0,
                  viewModel: viewModel,
                ),
                child: const Text('选择下载'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('选择下载'));
      await tester.pumpAndSettle();
      final button = find.byType(FilledButton);
      Material surface() => tester.widget<Material>(
        find.descendant(of: button, matching: find.byType(Material)).first,
      );
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(surface().color, theme.colorScheme.primary);
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .color,
        theme.colorScheme.onPrimary,
      );
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      await tester.tap(button);
      expect(repository.calls, 1);
      repository.gate.completeError(StateError('模拟失败'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
      expect(find.text('创建下载任务失败，请稍后重试'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  }
}

class _Repository extends ChangeNotifier implements DownloadRepository {
  final gate = Completer<List<VideoDownloadTask>>();
  int calls = 0;
  @override
  List<VideoDownloadTask> get tasks => [];
  @override
  bool get isInitialized => true;
  @override
  String? get initializationError => null;
  @override
  int get maxConcurrentDownloads => 3;
  @override
  Future<List<VideoDownloadTask>> enqueueEpisodes({
    required SearchResult detail,
    required Iterable<int> episodeIndexes,
  }) {
    calls++;
    return gate.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
