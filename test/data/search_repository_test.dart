import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/player_repository.dart';
import 'package:selene/data/repositories/search_repository.dart';
import 'package:selene/data/services/api_service.dart';
import 'package:selene/data/services/m3u8_service.dart';
import 'package:selene/data/services/moon_tv_api_service.dart';
import 'package:selene/data/services/search_source_service.dart';
import 'package:selene/domain/models/auth_models.dart';
import 'package:selene/domain/models/search_resource.dart';
import 'package:selene/domain/models/search_result.dart';
import 'package:selene/utils/result.dart';

void main() {
  test('本地搜索异常以 FailureResult 暴露，不伪装为空结果', () async {
    final repository = DefaultSearchRepository(
      apiService: ApiService(_FakeMoonTvClient()),
      sessionState: _LocalSession(),
      sourceService: _FailingSearchSourceService(),
    );

    final result = await repository.searchLocal('测试');

    expect(result, isA<FailureResult<List<SearchResult>>>());
    expect(result.failureOrNull?.message, '本地搜索失败');
  });

  test('本地多源搜索保留成功源结果并隔离单源失败', () async {
    final repository = DefaultSearchRepository(
      apiService: ApiService(_FakeMoonTvClient()),
      sessionState: _LocalSession(),
      sourceService: _PartiallyFailingSearchSourceService(),
    );

    final result = await repository.searchLocal('测试');

    expect(result, isA<Success<List<SearchResult>>>());
    expect(result.valueOrNull?.map((item) => item.id), <String>['available']);
  });

  test('PlayerRepository 释放其持有的 M3U8 分析器', () {
    final analyzer = _FakeM3u8Analyzer();
    final repository = DefaultPlayerRepository(
      apiService: ApiService(_FakeMoonTvClient()),
      m3u8Service: analyzer,
    );

    repository.dispose();

    expect(analyzer.disposed, isTrue);
  });

  test('清空搜索源缓存后在途旧刷新不会写回', () async {
    final client = _ControlledMoonTvClient();
    final first = client.enqueueResources('first')..complete();
    final stale = client.enqueueResources('stale');
    final latest = client.enqueueResources('latest');
    final sourceService = _RecordingSearchSourceService();
    final repository = DefaultSearchRepository(
      apiService: ApiService(client),
      sessionState: _AuthenticatedSession(),
      sourceService: sourceService,
    );

    expect((await repository.searchRecommendations('one')).isSuccess, isTrue);
    expect(first.isCompleted, isTrue);
    expect((await repository.searchRecommendations('two')).isSuccess, isTrue);
    expect(client.resourceRequestCount, 2);

    repository.clearCache();
    stale.complete();
    await Future<void>.delayed(Duration.zero);

    final pendingLatest = repository.searchRecommendations('three');
    expect(client.resourceRequestCount, 3);
    latest.complete();
    expect((await pendingLatest).isSuccess, isTrue);
    expect(sourceService.searchedResourceKeys.last, 'latest');
  });
}

final class _LocalSession implements SessionState {
  @override
  AuthStatus get status => AuthStatus.localMode;
}

final class _AuthenticatedSession implements SessionState {
  @override
  AuthStatus get status => AuthStatus.authenticated;
}

final class _FailingSearchSourceService implements SearchSourceService {
  @override
  Future<List<SearchResource>> getLocalSources() async => <SearchResource>[
    SearchResource(
      key: 'source',
      name: '测试源',
      api: 'https://example.com/api',
      detail: '',
      from: 'test',
      disabled: false,
    ),
  ];

  @override
  Future<List<SearchResult>> search(SearchResource resource, String query) =>
      Future<List<SearchResult>>.error(StateError('downstream failed'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _PartiallyFailingSearchSourceService
    implements SearchSourceService {
  @override
  Future<List<SearchResource>> getLocalSources() async => <SearchResource>[
    _resource('available'),
    _resource('unavailable'),
  ];

  @override
  Future<List<SearchResult>> search(
    SearchResource resource,
    String query,
  ) async {
    if (resource.key == 'unavailable') {
      throw StateError('downstream failed');
    }
    return <SearchResult>[
      SearchResult(
        id: 'available',
        title: query,
        poster: '',
        episodes: const <String>[],
        episodesTitles: const <String>[],
        source: resource.key,
        sourceName: resource.name,
        year: '2025',
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SearchResource _resource(String key) => SearchResource(
  key: key,
  name: key,
  api: 'https://example.com/$key',
  detail: '',
  from: 'test',
  disabled: false,
);

final class _FakeMoonTvClient implements MoonTvClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ControlledMoonTvClient implements MoonTvClient {
  final List<({String key, Completer<void> gate})> _responses = [];
  int resourceRequestCount = 0;

  Completer<void> enqueueResources(String key) {
    final gate = Completer<void>();
    _responses.add((key: key, gate: gate));
    return gate;
  }

  @override
  Future<Response<dynamic>> request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? queryParameters,
    Object? data,
    Map<String, String>? headers,
    bool replayable = true,
    ResponseType responseType = ResponseType.json,
    CancelToken? cancelToken,
  }) async {
    if (endpoint != '/api/search/resources' || _responses.isEmpty) {
      throw StateError('收到未预期请求: $endpoint');
    }
    resourceRequestCount++;
    final response = _responses.removeAt(0);
    await response.gate.future;
    return Response<dynamic>(
      requestOptions: RequestOptions(path: endpoint),
      statusCode: 200,
      data: <Map<String, Object?>>[
        <String, Object?>{
          'key': response.key,
          'name': response.key,
          'api': 'https://example.com/api',
          'detail': '',
          'from': 'test',
          'disabled': false,
        },
      ],
    );
  }

  @override
  void dispose() {}
}

final class _RecordingSearchSourceService implements SearchSourceService {
  final List<String> searchedResourceKeys = <String>[];

  @override
  Future<List<SearchResult>> search(
    SearchResource resource,
    String query,
  ) async {
    searchedResourceKeys.add(resource.key);
    return <SearchResult>[
      SearchResult(
        id: query,
        title: query,
        poster: '',
        episodes: const <String>['https://example.com/video.m3u8'],
        episodesTitles: const <String>['1'],
        source: resource.key,
        sourceName: resource.name,
        class_: '',
        year: '',
        desc: '',
        typeName: '',
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeM3u8Analyzer implements M3U8Analyzer {
  bool disposed = false;

  @override
  void dispose() => disposed = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
