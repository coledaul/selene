import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/library_repository.dart';
import 'package:selene/data/repositories/sse_search_repository.dart';
import 'package:selene/data/repositories/settings_repository.dart';
import 'package:selene/domain/models/app_settings.dart';
import 'package:selene/domain/models/search_progress.dart';
import 'package:selene/domain/models/search_result.dart';
import 'package:selene/domain/models/search_session_event.dart';
import 'package:selene/ui/search/view_models/search_ui_state.dart';
import 'package:selene/ui/search/view_models/search_view_model.dart';
import 'package:selene/utils/result.dart';

void main() {
  group('SearchViewModel', () {
    late _FakeLibraryRepository library;
    late _FakeSearchSession session;
    late SearchViewModel viewModel;

    setUp(() {
      library = _FakeLibraryRepository(history: <String>['旧记录']);
      session = _FakeSearchSession();
      viewModel = SearchViewModel(
        libraryRepository: library,
        searchSession: session,
        settingsRepository: _FakeSettingsRepository(),
      );
    });

    tearDown(() => viewModel.dispose());

    test('初始化从统一资料仓库读取搜索历史', () async {
      await viewModel.initialize();

      expect(viewModel.state.history, <String>['旧记录']);
      expect(library.historyReads, 1);
    });

    test('空查询返回校验失败且不会创建搜索会话', () async {
      final result = await viewModel.search('   ');

      expect(result, isA<FailureResult<void>>());
      expect(session.startedQueries, isEmpty);
    });

    test('流式结果和进度只写入不可变 UI 状态', () async {
      await viewModel.initialize();
      final result = await viewModel.search(' 三体 ');
      session
        ..emitResults(<SearchResult>[
          _result(id: '1', sourceName: '源甲', year: '2024'),
          _result(id: '2', sourceName: '源乙', year: '2022'),
        ])
        ..emitProgress(
          const SearchProgress(
            totalSources: 2,
            completedSources: 2,
            isComplete: true,
          ),
        );
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(result, isA<Success<void>>());
      expect(session.startedQueries, <String>['三体']);
      expect(viewModel.state.results.map((item) => item.id), <String>[
        '1',
        '2',
      ]);
      expect(viewModel.state.finished, isTrue);
      expect(viewModel.state.status, SearchStatus.success);
      expect(viewModel.state.history.first, '三体');
    });

    test('搜索启动期间立即发出的结果和完成事件不会丢失', () async {
      session.onStart = () {
        session
          ..emitResults(<SearchResult>[
            _result(id: 'instant', sourceName: '快速源', year: '2025'),
          ])
          ..emitProgress(
            const SearchProgress(
              totalSources: 1,
              completedSources: 1,
              isComplete: true,
            ),
          );
      };

      final result = await viewModel.search('即时结果');
      await Future<void>.delayed(Duration.zero);

      expect(result, isA<Success<void>>());
      expect(viewModel.state.results.single.id, 'instant');
      expect(viewModel.state.finished, isTrue);
    });

    test('失败终态原子更新状态和错误且不会伪装成空结果', () async {
      await viewModel.search('故障查询');

      session.emitProgress(
        const SearchProgress(
          totalSources: 1,
          completedSources: 1,
          isComplete: true,
          isFailure: true,
          error: '搜索连接意外结束，请重试',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.state.status, SearchStatus.failure);
      expect(viewModel.state.error, '搜索连接意外结束，请重试');
      expect(viewModel.state.warning, isNull);
      expect(viewModel.state.finished, isTrue);
    });

    test('失败终态不会被迟到的非终态进度恢复为搜索中', () async {
      await viewModel.search('故障查询');
      session
        ..emitProgress(
          const SearchProgress(
            totalSources: 1,
            completedSources: 1,
            isComplete: true,
            isFailure: true,
            error: '搜索超时（15秒）',
          ),
        )
        ..emitProgress(
          const SearchProgress(
            totalSources: 1,
            completedSources: 1,
            currentSource: '慢速源',
            isComplete: false,
          ),
        );
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.state.status, SearchStatus.failure);
      expect(viewModel.state.error, '搜索超时（15秒）');
      expect(viewModel.state.finished, isTrue);
    });

    test('部分源失败保留成功状态和非阻断警告', () async {
      await viewModel.search('部分结果');
      session
        ..emitResults(<SearchResult>[
          _result(id: 'partial', sourceName: '可用源', year: '2025'),
        ])
        ..emitProgress(
          const SearchProgress(
            totalSources: 2,
            completedSources: 2,
            isComplete: true,
            error: '部分搜索源失败，结果可能不完整',
          ),
        );
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.state.status, SearchStatus.success);
      expect(viewModel.state.results.single.id, 'partial');
      expect(viewModel.state.error, isNull);
      expect(viewModel.state.warning, '部分搜索源失败，结果可能不完整');
    });

    test('完成计数达到总数但没有终态事件时仍保持搜索中', () async {
      await viewModel.search('等待终态');

      session.emitProgress(
        const SearchProgress(
          totalSources: 1,
          completedSources: 1,
          isComplete: false,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.state.finished, isFalse);
    });

    test('快速连续搜索不会把上一查询的待合并结果写入新查询', () async {
      session.onStart = () {
        final query = session.startedQueries.last;
        session
          ..emitResults(<SearchResult>[
            _result(id: query, sourceName: '快速源', year: '2025'),
          ])
          ..emitProgress(
            const SearchProgress(
              totalSources: 1,
              completedSources: 1,
              isComplete: true,
            ),
          );
      };

      await viewModel.search('旧查询');
      await viewModel.search('新查询');
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(viewModel.state.query, '新查询');
      expect(viewModel.state.results.map((item) => item.id), <String>['新查询']);
      expect(viewModel.state.finished, isTrue);
    });

    test('两个搜索准备过程乱序完成时只有最新查询可以启动会话', () async {
      final settings = _ControlledSettingsRepository();
      final controlledSession = _FakeSearchSession();
      final controlledViewModel = SearchViewModel(
        libraryRepository: _FakeLibraryRepository(history: <String>[]),
        searchSession: controlledSession,
        settingsRepository: settings,
      );
      addTearDown(controlledViewModel.dispose);

      final oldSearch = controlledViewModel.search('旧查询');
      await Future<void>.delayed(Duration.zero);
      final newSearch = controlledViewModel.search('新查询');
      await Future<void>.delayed(Duration.zero);
      expect(settings.pendingLoads, 2);

      settings.completeAt(1);
      await newSearch;
      settings.completeAt(0);
      await oldSearch;

      expect(controlledSession.startedQueries, <String>['新查询']);
      expect(controlledViewModel.state.query, '新查询');
    });

    test('筛选和排序在状态层完成', () async {
      await viewModel.search('测试');
      session.emitResults(<SearchResult>[
        _result(id: '1', sourceName: '源甲', year: '2022'),
        _result(id: '2', sourceName: '源甲', year: '2024'),
        _result(id: '3', sourceName: '源乙', year: '2023'),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      viewModel
        ..setSource('源甲')
        ..cycleSortOrder();

      expect(viewModel.state.filteredResults.map((item) => item.id), <String>[
        '2',
        '1',
      ]);
      expect(viewModel.state.sortOrder, SearchSortOrder.descending);
    });

    test('历史删除失败时从仓库重新加载，避免 UI 与事实源分叉', () async {
      await viewModel.initialize();
      library
        ..deleteSucceeds = false
        ..history = <String>['服务端记录'];

      final result = await viewModel.deleteHistory('旧记录');

      expect(result, isA<FailureResult<void>>());
      expect(library.historyRefreshes, 1);
      expect(viewModel.state.history, <String>['服务端记录']);
    });

    test('收藏判断由 ViewModel 代理统一资料仓库', () {
      library.favoritedKeys.add('source-1/1');

      expect(viewModel.isFavorited('source-1', '1'), isTrue);
      expect(viewModel.isFavorited('source-2', '2'), isFalse);
    });

    test('销毁 ViewModel 同时释放搜索会话', () {
      viewModel.dispose();

      expect(session.disposed, isTrue);
      viewModel = SearchViewModel(
        libraryRepository: library,
        searchSession: _FakeSearchSession(),
        settingsRepository: _FakeSettingsRepository(),
      );
    });
  });
}

SearchResult _result({
  required String id,
  required String sourceName,
  required String year,
}) {
  return SearchResult(
    id: id,
    title: '标题$id',
    poster: '',
    episodes: const <String>[],
    episodesTitles: const <String>[],
    source: 'source-$id',
    sourceName: sourceName,
    year: year,
  );
}

final class _FakeLibraryRepository implements LibraryRepository {
  _FakeLibraryRepository({required this.history});

  List<String> history;
  bool deleteSucceeds = true;
  int historyReads = 0;
  int historyRefreshes = 0;
  final Set<String> favoritedKeys = <String>{};

  @override
  bool isFavorited(String source, String id) =>
      favoritedKeys.contains('$source/$id');

  @override
  Future<Result<List<String>>> getSearchHistory({
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) historyRefreshes++;
    historyReads++;
    return Success<List<String>>(List<String>.of(history));
  }

  @override
  Future<Result<void>> addSearchHistory(String query) async {
    history = <String>[query, ...history.where((item) => item != query)];
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> deleteSearchHistory(String query) async {
    if (!deleteSucceeds) {
      return const FailureResult<void>(
        AppFailure(kind: FailureKind.network, message: '删除失败'),
      );
    }
    history = history.where((item) => item != query).toList();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> clearSearchHistory() async {
    history = <String>[];
    return const Success<void>(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeSearchSession implements SSESearchRepository {
  final StreamController<SearchSessionEvent> _events =
      StreamController<SearchSessionEvent>.broadcast();
  final List<String> startedQueries = <String>[];
  void Function()? onStart;
  bool disposed = false;

  void emitResults(List<SearchResult> results) =>
      _events.add(SearchSessionResults(results));

  void emitProgress(SearchProgress progress) =>
      _events.add(SearchSessionProgress(progress));

  @override
  Stream<SearchSessionEvent> get events => _events.stream;

  @override
  Future<void> startSearch(
    String query, {
    required bool localSearchEnabled,
  }) async {
    startedQueries.add(query);
    onStart?.call();
  }

  @override
  Future<void> stopSearch() async {}

  @override
  void dispose() {
    disposed = true;
    _events.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeSettingsRepository implements SettingsRepository {
  @override
  Future<Result<AppSettings>> load() async =>
      const Success<AppSettings>(AppSettings());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ControlledSettingsRepository implements SettingsRepository {
  final List<Completer<Result<AppSettings>>> _loads =
      <Completer<Result<AppSettings>>>[];

  int get pendingLoads => _loads.length;

  void completeAt(int index) {
    _loads[index].complete(const Success<AppSettings>(AppSettings()));
  }

  @override
  Future<Result<AppSettings>> load() {
    final completer = Completer<Result<AppSettings>>();
    _loads.add(completer);
    return completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
