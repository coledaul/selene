import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/sse_search_repository.dart';
import 'package:selene/data/services/api_service.dart';
import 'package:selene/data/services/moon_tv_api_service.dart';
import 'package:selene/data/services/search_source_service.dart';
import 'package:selene/data/services/search_stream_service.dart';
import 'package:selene/domain/models/auth_models.dart';
import 'package:selene/domain/models/search_progress.dart';
import 'package:selene/domain/models/search_resource.dart';
import 'package:selene/domain/models/search_result.dart';
import 'package:selene/domain/models/search_session_event.dart';

void main() {
  group('DefaultSSESearchRepository', () {
    test('搜索启动前订阅的稳定事件流可以收到即时结果和完成事件', () async {
      final streamService = _QueuedSearchStreamService()
        ..enqueue(
          _sseStream(<String>[
            _startEvent(),
            _sourceResultEvent(),
            _completeEvent(),
          ]),
        );
      final repository = _repository(streamService);
      final log = _EventLog(repository);

      await repository.startSearch('测试', localSearchEnabled: false);
      await _flushEvents();

      expect(log.progress.map((item) => item.isComplete), <bool>[
        false,
        false,
        true,
      ]);
      expect(log.resultIds, <String>['instant']);
      expect(log.eventTypes, <Type>[
        SearchSessionProgress,
        SearchSessionResults,
        SearchSessionProgress,
        SearchSessionProgress,
      ]);
      await log.close();
      repository.dispose();
    });

    test('连接关闭但没有 complete 事件时提交失败终态而不是空结果', () async {
      final streamService = _QueuedSearchStreamService()
        ..enqueue(_sseStream(<String>[_startEvent()]));
      final repository = _repository(streamService);
      final log = _EventLog(repository);

      await repository.startSearch('测试', localSearchEnabled: false);
      await _flushEvents();

      expect(log.progress.where((item) => item.isComplete), hasLength(1));
      expect(log.progress.last.isFailure, isTrue);
      expect(log.progress.last.error, '搜索连接意外结束，请重试');
      await log.close();
      repository.dispose();
    });

    test('明确 complete 且搜索源成功返回空列表时是真实空结果', () async {
      final streamService = _QueuedSearchStreamService()
        ..enqueue(
          _sseStream(<String>[
            _startEvent(),
            _sourceResultEvent(results: const <Map<String, Object?>>[]),
            _completeEvent(),
          ]),
        );
      final repository = _repository(streamService);
      final log = _EventLog(repository);

      await repository.startSearch('测试', localSearchEnabled: false);
      await _flushEvents();

      expect(log.progress.last.isComplete, isTrue);
      expect(log.progress.last.isFailure, isFalse);
      expect(log.progress.last.error, isNull);
      await log.close();
      repository.dispose();
    });

    test('所有搜索源失败时不能显示为未找到结果', () async {
      final streamService = _QueuedSearchStreamService()
        ..enqueue(
          _sseStream(<String>[
            _startEvent(),
            _sourceErrorEvent(source: 'broken'),
            _completeEvent(),
          ]),
        );
      final repository = _repository(streamService);
      final log = _EventLog(repository);

      await repository.startSearch('测试', localSearchEnabled: false);
      await _flushEvents();

      expect(log.progress.last.isFailure, isTrue);
      expect(log.progress.last.error, '所有搜索源均失败，请稍后重试');
      await log.close();
      repository.dispose();
    });

    test('部分搜索源失败时保留成功结果并提交非阻断警告', () async {
      final streamService = _QueuedSearchStreamService()
        ..enqueue(
          _sseStream(<String>[
            _startEvent(totalSources: 2),
            _sourceErrorEvent(source: 'broken'),
            _sourceResultEvent(),
            _completeEvent(completedSources: 2),
          ]),
        );
      final repository = _repository(streamService);
      final log = _EventLog(repository);

      await repository.startSearch('测试', localSearchEnabled: false);
      await _flushEvents();

      expect(log.resultIds, <String>['instant']);
      expect(log.progress.last.isComplete, isTrue);
      expect(log.progress.last.isFailure, isFalse);
      expect(log.progress.last.error, '部分搜索源失败，结果可能不完整');
      await log.close();
      repository.dispose();
    });

    test('无法解析 SSE 数据时提交安全的协议失败而不是空结果', () async {
      final streamService = _QueuedSearchStreamService()
        ..enqueue(_sseStream(<String>[_startEvent(), 'data: {invalid-json']));
      final repository = _repository(streamService);
      final log = _EventLog(repository);

      await repository.startSearch('测试', localSearchEnabled: false);
      await _flushEvents();

      expect(log.progress.last.isFailure, isTrue);
      expect(log.progress.last.error, '搜索数据解析失败，请重试');
      await log.close();
      repository.dispose();
    });

    test('complete 声明的结果多于已接收结果时提交不完整失败', () async {
      final streamService = _QueuedSearchStreamService()
        ..enqueue(
          _sseStream(<String>[
            _startEvent(),
            _sourceResultEvent(),
            _completeEvent(totalResults: 3),
          ]),
        );
      final repository = _repository(streamService);
      final log = _EventLog(repository);

      await repository.startSearch('测试', localSearchEnabled: false);
      await _flushEvents();

      expect(log.resultIds, <String>['instant']);
      expect(log.progress.last.isFailure, isTrue);
      expect(log.progress.last.error, '搜索结果接收不完整，请重试');
      await log.close();
      repository.dispose();
    });

    test('连接关闭前会解析缓冲区内没有换行的最后一个事件', () async {
      final trailingComplete =
          '${_startEvent()}\n\ndata: ${_completeJson(completedSources: 3)}';
      final streamService = _QueuedSearchStreamService()
        ..enqueue(Stream<List<int>>.value(utf8.encode(trailingComplete)));
      final repository = _repository(streamService);
      final log = _EventLog(repository);

      await repository.startSearch('测试', localSearchEnabled: false);
      await _flushEvents();

      expect(log.progress.where((item) => item.isComplete), hasLength(1));
      expect(log.progress.last.completedSources, 3);
      await log.close();
      repository.dispose();
    });

    test('SSE 错误会同时发布错误和完成状态而不是永久加载', () async {
      final streamService = _QueuedSearchStreamService()
        ..enqueue(Stream<List<int>>.error(StateError('连接中断')));
      final repository = _repository(streamService);
      final log = _EventLog(repository);

      await repository.startSearch('测试', localSearchEnabled: false);
      await _flushEvents();

      expect(log.progress.where((item) => item.isComplete), hasLength(1));
      expect(log.progress.last.isFailure, isTrue);
      expect(log.progress.last.error, '搜索连接异常，请重试');
      await log.close();
      repository.dispose();
    });

    test('本地搜索没有可用源时提交错误终态', () async {
      final repository = DefaultSSESearchRepository(
        apiService: ApiService(_UnusedMoonTvClient()),
        streamService: _QueuedSearchStreamService(),
        sessionState: _LocalSession(),
        sourceService: _EmptySearchSourceService(),
      );
      final log = _EventLog(repository);

      await repository.startSearch('测试', localSearchEnabled: true);
      await _flushEvents();

      expect(log.progress.single.isComplete, isTrue);
      expect(log.progress.single.isFailure, isTrue);
      expect(log.progress.single.error, '没有可用的搜索资源');
      await log.close();
      repository.dispose();
    });

    test('本地搜索即时完成时仍按开始结果完成顺序发布', () async {
      final repository = DefaultSSESearchRepository(
        apiService: ApiService(_UnusedMoonTvClient()),
        streamService: _QueuedSearchStreamService(),
        sessionState: _LocalSession(),
        sourceService: _ImmediateSearchSourceService(),
      );
      final log = _EventLog(repository);

      await repository.startSearch('本地', localSearchEnabled: true);
      await _flushEvents();

      expect(log.progress.map((item) => item.isComplete), <bool>[
        false,
        false,
        true,
      ]);
      expect(log.resultIds, <String>['local']);
      await log.close();
      repository.dispose();
    });

    test('本地搜索提交终态后丢弃迟到的源结果和非终态进度', () async {
      final sourceService = _ControlledSearchSourceService();
      final repository = DefaultSSESearchRepository(
        apiService: ApiService(_UnusedMoonTvClient()),
        streamService: _QueuedSearchStreamService(),
        sessionState: _LocalSession(),
        sourceService: sourceService,
        overallTimeout: const Duration(milliseconds: 10),
        sourceTimeout: const Duration(seconds: 1),
      );
      final log = _EventLog(repository);

      await repository.startSearch('本地', localSearchEnabled: true);
      await sourceService.started.future;
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(log.progress.last.isComplete, isTrue);
      expect(log.progress.last.isFailure, isTrue);
      final eventCountAtTerminal = log.eventTypes.length;

      sourceService.complete();
      await _flushEvents();

      expect(log.eventTypes, hasLength(eventCountAtTerminal));
      expect(log.resultIds, isEmpty);
      expect(log.progress.where((item) => item.isComplete), hasLength(1));
      await log.close();
      repository.dispose();
    });

    test('连续搜索复用公开流且旧搜索关闭不会结束新搜索事件流', () async {
      final firstController = StreamController<List<int>>();
      final streamService = _QueuedSearchStreamService()
        ..enqueue(firstController.stream)
        ..enqueue(_sseStream(<String>[_startEvent(), _completeEvent()]));
      final repository = _repository(streamService);
      final log = _EventLog(repository);

      await repository.startSearch('旧搜索', localSearchEnabled: false);
      await repository.startSearch('新搜索', localSearchEnabled: false);
      await _flushEvents();

      expect(repository.currentQuery, '新搜索');
      expect(log.progress.where((item) => item.isComplete), hasLength(1));
      expect(streamService.connections.first.cancelled, isTrue);
      await firstController.close();
      await log.close();
      repository.dispose();
    });
  });
}

DefaultSSESearchRepository _repository(SearchStreamService streamService) {
  return DefaultSSESearchRepository(
    apiService: ApiService(_UnusedMoonTvClient()),
    streamService: streamService,
    sessionState: _AuthenticatedSession(),
  );
}

Stream<List<int>> _sseStream(List<String> events) {
  return Stream<List<int>>.fromIterable(<List<int>>[
    utf8.encode('${events.join('\n\n')}\n\n'),
  ]);
}

String _startEvent({int totalSources = 1}) =>
    'data: ${jsonEncode(<String, Object?>{'type': 'start', 'query': '测试', 'totalSources': totalSources, 'timestamp': 1})}';

String _completeEvent({int completedSources = 1, int totalResults = 0}) =>
    'data: ${_completeJson(completedSources: completedSources, totalResults: totalResults)}';

String _sourceResultEvent({
  List<Map<String, Object?>> results = const <Map<String, Object?>>[
    <String, Object?>{
      'id': 'instant',
      'title': '即时结果',
      'poster': '',
      'episodes': <String>[],
      'episodes_titles': <String>[],
      'source': 'fast',
      'source_name': '快速源',
      'year': '2025',
    },
  ],
}) =>
    'data: ${jsonEncode(<String, Object?>{'type': 'source_result', 'source': 'fast', 'sourceName': '快速源', 'timestamp': 2, 'results': results})}';

String _sourceErrorEvent({required String source}) =>
    'data: ${jsonEncode(<String, Object?>{'type': 'source_error', 'source': source, 'sourceName': '故障源', 'error': '上游不可用', 'timestamp': 2})}';

String _completeJson({int completedSources = 1, int totalResults = 0}) =>
    jsonEncode(<String, Object?>{
      'type': 'complete',
      'totalResults': totalResults,
      'completedSources': completedSources,
      'timestamp': 2,
    });

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

final class _EventLog {
  _EventLog(SSESearchRepository repository) {
    _subscription = repository.events.listen(_record);
  }

  late final StreamSubscription<SearchSessionEvent> _subscription;
  final List<SearchProgress> progress = <SearchProgress>[];
  final List<String> resultIds = <String>[];
  final List<Type> eventTypes = <Type>[];

  void _record(SearchSessionEvent event) {
    eventTypes.add(event.runtimeType);
    switch (event) {
      case SearchSessionResults(:final results):
        resultIds.addAll(results.map((result) => result.id));
      case SearchSessionProgress(:final progress):
        this.progress.add(progress);
    }
  }

  Future<void> close() => _subscription.cancel();
}

final class _QueuedSearchStreamService implements SearchStreamService {
  final List<Stream<List<int>>> _streams = <Stream<List<int>>>[];
  final List<_FakeSearchStreamConnection> connections =
      <_FakeSearchStreamConnection>[];

  void enqueue(Stream<List<int>> stream) => _streams.add(stream);

  @override
  Future<SearchStreamConnection> open(String query) async {
    final connection = _FakeSearchStreamConnection(_streams.removeAt(0));
    connections.add(connection);
    return connection;
  }
}

final class _FakeSearchStreamConnection implements SearchStreamConnection {
  _FakeSearchStreamConnection(this.bytes);

  @override
  final Stream<List<int>> bytes;
  bool cancelled = false;

  @override
  void cancel() => cancelled = true;
}

final class _AuthenticatedSession implements SessionState {
  @override
  AuthStatus get status => AuthStatus.authenticated;
}

final class _LocalSession implements SessionState {
  @override
  AuthStatus get status => AuthStatus.localMode;
}

final class _EmptySearchSourceService implements SearchSourceService {
  @override
  Future<List<SearchResource>> getLocalSources() async => <SearchResource>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ImmediateSearchSourceService implements SearchSourceService {
  @override
  Future<List<SearchResource>> getLocalSources() async => <SearchResource>[
    SearchResource(
      key: 'local',
      name: '本地源',
      api: 'https://example.com/api',
      detail: '',
      from: 'test',
      disabled: false,
    ),
  ];

  @override
  Future<List<SearchResult>> search(
    SearchResource resource,
    String query,
  ) async => <SearchResult>[
    SearchResult(
      id: 'local',
      title: query,
      poster: '',
      episodes: const <String>[],
      episodesTitles: const <String>[],
      source: resource.key,
      sourceName: resource.name,
      year: '2025',
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ControlledSearchSourceService implements SearchSourceService {
  final Completer<void> started = Completer<void>();
  final Completer<List<SearchResult>> _results =
      Completer<List<SearchResult>>();

  void complete() {
    _results.complete(<SearchResult>[
      SearchResult(
        id: 'late',
        title: '迟到结果',
        poster: '',
        episodes: const <String>[],
        episodesTitles: const <String>[],
        source: 'slow',
        sourceName: '慢速源',
        year: '2025',
      ),
    ]);
  }

  @override
  Future<List<SearchResource>> getLocalSources() async => <SearchResource>[
    SearchResource(
      key: 'slow',
      name: '慢速源',
      api: 'https://example.com/api',
      detail: '',
      from: 'test',
      disabled: false,
    ),
  ];

  @override
  Future<List<SearchResult>> search(SearchResource resource, String query) {
    if (!started.isCompleted) {
      started.complete();
    }
    return _results.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _UnusedMoonTvClient implements MoonTvClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
