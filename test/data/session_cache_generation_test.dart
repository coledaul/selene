import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/library_repository.dart';
import 'package:selene/data/repositories/live_repository.dart';
import 'package:selene/data/services/api_service.dart';
import 'package:selene/data/services/moon_tv_api_service.dart';
import 'package:selene/domain/models/auth_models.dart';

void main() {
  test('Library 清缓存后在途旧身份响应不会重新写回', () async {
    final client = _QueuedMoonTvClient();
    final oldResponse = client.enqueue('/api/playrecords');
    final repository = DefaultLibraryRepository(
      apiService: ApiService(client),
      sessionState: _AuthenticatedSession(),
    );

    final pending = repository.getPlayRecords(forceRefresh: true);
    await _flushAsyncWork();
    expect(client.requestCount('/api/playrecords'), 1);

    repository.clearAllCache();
    oldResponse.complete(_response('/api/playrecords', _playRecords('old')));
    expect((await pending).valueOrNull?.single.id, 'old');

    final freshResponse = client.enqueue('/api/playrecords')
      ..complete(_response('/api/playrecords', _playRecords('fresh')));
    final fresh = await repository.getPlayRecords();

    expect(freshResponse.isCompleted, isTrue);
    expect(client.requestCount('/api/playrecords'), 2);
    expect(fresh.valueOrNull?.single.id, 'fresh');
  });

  test('Live 清缓存后在途旧身份响应不会重新写回', () async {
    final client = _QueuedMoonTvClient();
    final oldResponse = client.enqueue('/api/live/sources');
    final repository = DefaultLiveRepository(
      apiService: ApiService(client),
      sessionState: _AuthenticatedSession(),
    );

    final pending = repository.getLiveSources(forceRefresh: true);
    await _flushAsyncWork();
    expect(client.requestCount('/api/live/sources'), 1);

    repository.clearAllCache();
    oldResponse.complete(_response('/api/live/sources', _liveSources('old')));
    expect((await pending).valueOrNull?.single.key, 'old');

    final freshResponse = client.enqueue('/api/live/sources')
      ..complete(_response('/api/live/sources', _liveSources('fresh')));
    final fresh = await repository.getLiveSources();

    expect(freshResponse.isCompleted, isTrue);
    expect(client.requestCount('/api/live/sources'), 2);
    expect(fresh.valueOrNull?.single.key, 'fresh');
  });
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Response<dynamic> _response(String path, Object data) => Response<dynamic>(
  requestOptions: RequestOptions(path: path),
  statusCode: 200,
  data: data,
);

Map<String, dynamic> _playRecords(String id) => <String, dynamic>{
  'source+$id': <String, dynamic>{
    'title': id,
    'source_name': '测试源',
    'year': '2025',
    'cover': '',
    'index': 0,
    'total_episodes': 1,
    'play_time': 0,
    'total_time': 0,
    'save_time': 1,
    'search_title': id,
  },
};

Map<String, dynamic> _liveSources(String key) => <String, dynamic>{
  'data': <Map<String, dynamic>>[
    <String, dynamic>{
      'key': key,
      'name': key,
      'url': 'https://example.com/$key.m3u',
      'ua': '',
      'epg': '',
      'from': 'test',
      'disabled': false,
    },
  ],
};

final class _QueuedMoonTvClient implements MoonTvClient {
  final Map<String, List<Completer<Response<dynamic>>>> _responses =
      <String, List<Completer<Response<dynamic>>>>{};
  final Map<String, int> _requestCounts = <String, int>{};

  Completer<Response<dynamic>> enqueue(String endpoint) {
    final completer = Completer<Response<dynamic>>();
    _responses.putIfAbsent(endpoint, () => []).add(completer);
    return completer;
  }

  int requestCount(String endpoint) => _requestCounts[endpoint] ?? 0;

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
  }) {
    _requestCounts.update(endpoint, (value) => value + 1, ifAbsent: () => 1);
    final queue = _responses[endpoint];
    if (queue == null || queue.isEmpty) {
      throw StateError('收到未排队的请求: $endpoint');
    }
    return queue.removeAt(0).future;
  }

  @override
  void dispose() {}
}

final class _AuthenticatedSession implements SessionState {
  @override
  AuthStatus get status => AuthStatus.authenticated;
}
