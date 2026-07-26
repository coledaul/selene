import 'dart:convert';
import 'dart:async';
import '../../domain/models/auth_models.dart';
import '../../domain/models/search_resource.dart';
import '../../domain/models/search_result.dart';
import '../../domain/models/search_progress.dart';
import '../../domain/models/search_session_event.dart';
import '../services/api_service.dart';
import '../services/search_source_service.dart';
import '../services/search_stream_service.dart';
import '../../utils/app_logger.dart';

/// SSE 搜索服务
abstract interface class SSESearchRepository {
  Stream<SearchSessionEvent> get events;
  bool get isConnected;
  String? get currentQuery;
  Map<String, String> get sourceErrors;
  Future<void> startSearch(String query, {required bool localSearchEnabled});
  Future<void> stopSearch();
  void dispose();
}

final class DefaultSSESearchRepository implements SSESearchRepository {
  DefaultSSESearchRepository({
    required ApiService apiService,
    required SearchStreamService streamService,
    required SessionState sessionState,
    SearchSourceService? sourceService,
    Duration overallTimeout = const Duration(seconds: 15),
    Duration sourceTimeout = const Duration(seconds: 20),
  }) : _apiService = apiService,
       _streamService = streamService,
       _sessionState = sessionState,
       _sourceService = sourceService ?? const DefaultSearchSourceService(),
       _overallTimeout = overallTimeout,
       _sourceTimeout = sourceTimeout,
       assert(overallTimeout > Duration.zero),
       assert(sourceTimeout > Duration.zero);

  final ApiService _apiService;
  final SearchStreamService _streamService;
  final SessionState _sessionState;
  final SearchSourceService _sourceService;
  final Duration _overallTimeout;
  final Duration _sourceTimeout;

  SearchStreamConnection? _connection;
  StreamSubscription? _subscription;
  final StreamController<SearchSessionEvent> _eventController =
      StreamController<SearchSessionEvent>.broadcast();

  bool _isConnected = false;
  String? _currentQuery;
  final Map<String, String> _sourceErrors = {};
  String _buffer = ''; // 用于缓冲不完整的 UTF-8 字符
  int _completedSources = 0; // 跟踪完成的源数量
  int _totalSources = 0; // 总源数量
  int _successfulSources = 0;
  int _failedSources = 0;
  int _receivedResults = 0;
  bool _receivedStartEvent = false;
  Timer? _timeoutTimer; // 超时定时器
  int _searchGeneration = 0;
  bool _terminalEmitted = true;
  bool _disposed = false;

  /// 单一有序事件流保证结果、进度和终态按协议顺序交付。
  @override
  Stream<SearchSessionEvent> get events => _eventController.stream;

  /// 是否已连接
  @override
  bool get isConnected => _isConnected;

  /// 当前搜索查询
  @override
  String? get currentQuery => _currentQuery;

  /// 本地搜索
  Future<void> localSearch(String query, int generation) async {
    try {
      // 检查是否是本地模式
      final isLocalMode = _sessionState.status == AuthStatus.localMode;

      // 获取搜索资源列表
      final allResources = isLocalMode
          ? await _sourceService.getLocalSources()
          : await _apiService.getSearchResources();
      if (!_isCurrent(generation)) return;

      // 过滤掉被禁用的资源
      final resources = allResources
          .where((resource) => !resource.disabled)
          .toList();

      if (resources.isEmpty) {
        _finishSearch(error: '没有可用的搜索资源', isFailure: true);
        return;
      }

      _totalSources = resources.length;
      _completedSources = 0;
      _successfulSources = 0;
      _failedSources = 0;
      _receivedResults = 0;

      _addProgress(
        SearchProgress(
          totalSources: _totalSources,
          completedSources: 0,
          currentSource: null,
          isComplete: false,
        ),
      );

      // 并发调用所有资源的搜索，每个调用增加 20 秒超时
      final searchFutures = resources.map((resource) {
        return _searchSingleResource(resource, query, generation);
      }).toList();

      // 等待所有搜索完成
      await Future.wait(searchFutures);

      // 发送完成事件
      if (!_isCurrent(generation)) return;
      _finishSourceSearch();
    } catch (e) {
      if (!_isCurrent(generation)) return;
      AppLogger.debug('本地搜索异常：${e.runtimeType}');
      _finishSearch(error: '本地搜索失败，请重试', isFailure: true);
    }
  }

  /// 搜索单个资源
  Future<void> _searchSingleResource(
    SearchResource resource,
    String query,
    int generation,
  ) async {
    try {
      // 调用 searchFromApi 并设置 20 秒超时
      final results = await _sourceService
          .search(resource, query)
          .timeout(_sourceTimeout);

      if (!_isCurrent(generation)) return;
      // 增加完成计数
      _completedSources++;
      _successfulSources++;
      _receivedResults += results.length;

      // 发送结果事件
      if (results.isNotEmpty) {
        _addResults(results);
      }

      // 发送进度更新
      _addProgress(
        SearchProgress(
          totalSources: _totalSources,
          completedSources: _completedSources,
          currentSource: resource.name,
          isComplete: false,
        ),
      );
    } on TimeoutException {
      if (!_isCurrent(generation)) return;
      // 超时处理
      _completedSources++;
      _failedSources++;
      _sourceErrors[resource.key] = '搜索超时（20秒）';

      // 发送错误进度更新
      _addProgress(
        SearchProgress(
          totalSources: _totalSources,
          completedSources: _completedSources,
          currentSource: resource.name,
          isComplete: false,
          error: '当前搜索源超时',
        ),
      );
    } catch (e) {
      if (!_isCurrent(generation)) return;
      // 其他错误处理
      _completedSources++;
      _failedSources++;
      _sourceErrors[resource.key] = e.toString();

      // 发送错误进度更新
      _addProgress(
        SearchProgress(
          totalSources: _totalSources,
          completedSources: _completedSources,
          currentSource: resource.name,
          isComplete: false,
          error: '当前搜索源失败',
        ),
      );
    }
  }

  /// 开始搜索
  @override
  Future<void> startSearch(
    String query, {
    required bool localSearchEnabled,
  }) async {
    if (_disposed) {
      throw StateError('搜索会话已经释放');
    }
    if (query.trim().isEmpty) {
      throw Exception('搜索查询不能为空');
    }

    // 每次搜索只重置当前连接，公开事件流与 Repository 同生命周期。
    await _stopActiveSearch(clearQuery: false);

    _currentQuery = query.trim();
    final generation = ++_searchGeneration;
    _sourceErrors.clear();
    _completedSources = 0;
    _totalSources = 0;
    _successfulSources = 0;
    _failedSources = 0;
    _receivedResults = 0;
    _receivedStartEvent = false;
    _terminalEmitted = false;
    _isConnected = true;

    // 设置15秒超时定时器
    _timeoutTimer = Timer(_overallTimeout, () {
      if (_isCurrent(generation)) {
        _handleTimeout();
      }
    });

    // 检查是否启用本地搜索或本地模式
    final isLocalMode = _sessionState.status == AuthStatus.localMode;
    if (isLocalMode || localSearchEnabled) {
      unawaited(localSearch(query, generation));
      return;
    }

    try {
      final connection = await _streamService.open(_currentQuery!);
      if (!_isCurrent(generation)) {
        connection.cancel();
        return;
      }
      _connection = connection;

      _buffer = '';
      _subscription = connection.bytes
          .transform(utf8.decoder)
          .listen(
            (chunk) {
              if (_isCurrent(generation)) {
                _handleSSEChunk(chunk);
              }
            },
            onError: (error) {
              if (!_isCurrent(generation)) return;
              // 静默处理连接关闭错误，不显示给用户
              final errorString = error.toString().toLowerCase();
              if (errorString.contains('connection closed') ||
                  errorString.contains('clientexception') ||
                  errorString.contains('connection terminated')) {
                _handleDone();
                return;
              }
              _handleError(error);
            },
            onDone: () {
              if (_isCurrent(generation)) {
                _handleDone();
              }
            },
          );
    } catch (e) {
      if (!_isCurrent(generation)) return;
      AppLogger.debug('搜索连接建立失败：${e.runtimeType}');
      _finishSearch(error: '无法连接搜索服务，请重试', isFailure: true);
      rethrow;
    }
  }

  /// 处理 SSE 文本块
  void _handleSSEChunk(String chunk) {
    _buffer += chunk;
    final lines = _buffer.split('\n');
    if (lines.isNotEmpty) {
      _buffer = lines.removeLast();
    }

    for (final line in lines) {
      _handleSSELine(line);
    }
  }

  void _handleSSELine(String line) {
    final normalized = line.trimRight();
    if (!normalized.startsWith('data:')) return;
    final data = normalized.substring(5).trimLeft();
    if (data.isNotEmpty) {
      _handleSSEData(data);
    }
  }

  /// 处理 SSE 数据
  void _handleSSEData(String jsonStr) {
    try {
      final data = json.decode(jsonStr);

      final event = SearchEvent.fromJson(data as Map<String, dynamic>);

      switch (event.type) {
        case SearchEventType.start:
          _handleStartEvent(event as SearchStartEvent);
          break;
        case SearchEventType.sourceResult:
          _handleSourceResultEvent(event as SearchSourceResultEvent);
          break;
        case SearchEventType.sourceError:
          _handleSourceErrorEvent(event as SearchSourceErrorEvent);
          break;
        case SearchEventType.complete:
          _handleCompleteEvent(event as SearchCompleteEvent);
          break;
      }
    } catch (e) {
      AppLogger.debug('搜索数据解析失败：${e.runtimeType}');
      _finishSearch(error: '搜索数据解析失败，请重试', isFailure: true);
    }
  }

  /// 处理开始事件
  void _handleStartEvent(SearchStartEvent event) {
    if (_terminalEmitted) return;
    _receivedStartEvent = true;
    _totalSources = event.totalSources;
    _addProgress(
      SearchProgress(
        totalSources: event.totalSources,
        completedSources: 0,
        currentSource: null,
        isComplete: false,
      ),
    );
  }

  /// 处理搜索结果事件
  void _handleSourceResultEvent(SearchSourceResultEvent event) {
    if (_terminalEmitted) return;
    if (!_receivedStartEvent) {
      _finishSearch(error: '搜索数据顺序异常，请重试', isFailure: true);
      return;
    }
    _completedSources++;
    _successfulSources++;
    _receivedResults += event.results.length;

    // 只发送增量结果更新，避免全量重渲染
    if (event.results.isNotEmpty) {
      _addResults(event.results);
    }

    // 更新进度（无论是否有结果都要更新）
    _addProgress(
      SearchProgress(
        totalSources: _totalSources,
        completedSources: _completedSources,
        currentSource: event.sourceName,
        isComplete: false,
      ),
    );
  }

  /// 处理搜索错误事件
  void _handleSourceErrorEvent(SearchSourceErrorEvent event) {
    if (_terminalEmitted) return;
    if (!_receivedStartEvent) {
      _finishSearch(error: '搜索数据顺序异常，请重试', isFailure: true);
      return;
    }
    _sourceErrors[event.source] = event.error;

    // 错误也算源完成，累计进度
    _completedSources++;
    _failedSources++;

    // 更新进度
    _addProgress(
      SearchProgress(
        totalSources: _totalSources,
        completedSources: _completedSources,
        currentSource: event.sourceName,
        isComplete: false,
        error: '当前搜索源失败',
      ),
    );
  }

  /// 处理完成事件
  void _handleCompleteEvent(SearchCompleteEvent event) {
    if (!_receivedStartEvent) {
      _finishSearch(error: '搜索数据顺序异常，请重试', isFailure: true);
      return;
    }
    _completedSources = event.completedSources > _completedSources
        ? event.completedSources
        : _completedSources;
    if (event.totalResults > _receivedResults) {
      AppLogger.debug(
        '搜索完成事件与接收结果不一致：'
        'expected=${event.totalResults}, received=$_receivedResults',
      );
      _finishSearch(error: '搜索结果接收不完整，请重试', isFailure: true);
      return;
    }
    _finishSourceSearch();
  }

  /// 处理超时
  void _handleTimeout() {
    _finishSearch(error: '搜索超时（15秒）', isFailure: true);
  }

  /// 关闭连接
  void _closeConnection() {
    _isConnected = false;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _connection?.cancel();
    _connection = null;
  }

  /// 处理 SSE 错误
  void _handleError(Object error) {
    AppLogger.debug('搜索连接异常：${error.runtimeType}');
    _finishSearch(error: '搜索连接异常，请重试', isFailure: true);
  }

  /// 处理 SSE 关闭
  void _handleDone() {
    if (_terminalEmitted) return;
    _flushTrailingSSEData();
    if (_terminalEmitted) return;
    AppLogger.debug(
      '搜索连接在完成事件前结束：'
      'total=$_totalSources, success=$_successfulSources, failed=$_failedSources',
    );
    _finishSearch(error: '搜索连接意外结束，请重试', isFailure: true);
  }

  void _flushTrailingSSEData() {
    final trailing = _buffer;
    _buffer = '';
    if (trailing.trim().isNotEmpty) {
      _handleSSELine(trailing);
    }
  }

  void _finishSourceSearch() {
    if (_successfulSources == 0 && _failedSources > 0) {
      _finishSearch(error: '所有搜索源均失败，请稍后重试', isFailure: true);
      return;
    }

    final observedSources = _successfulSources + _failedSources;
    final hasIncompleteSources = observedSources < _totalSources;
    final hasPartialFailure = _failedSources > 0 || hasIncompleteSources;
    _finishSearch(error: hasPartialFailure ? '部分搜索源失败，结果可能不完整' : null);
  }

  void _finishSearch({String? error, bool isFailure = false}) {
    if (_terminalEmitted || _disposed) return;
    _terminalEmitted = true;
    if (_completedSources < _totalSources) {
      _completedSources = _totalSources;
    }
    _addProgress(
      SearchProgress(
        totalSources: _totalSources,
        completedSources: _completedSources,
        currentSource: null,
        isComplete: true,
        isFailure: isFailure,
        error: error,
      ),
    );
    _closeConnection();
  }

  void _addResults(List<SearchResult> results) {
    if (_disposed || _terminalEmitted) return;
    _eventController.add(SearchSessionResults(results));
  }

  void _addProgress(SearchProgress progress) {
    if (_disposed || (_terminalEmitted && !progress.isComplete)) return;
    _eventController.add(SearchSessionProgress(progress));
  }

  bool _isCurrent(int generation) =>
      !_disposed && !_terminalEmitted && generation == _searchGeneration;

  /// 停止搜索
  @override
  Future<void> stopSearch() => _stopActiveSearch(clearQuery: true);

  Future<void> _stopActiveSearch({required bool clearQuery}) async {
    _searchGeneration++;
    _terminalEmitted = true;
    await _subscription?.cancel();
    _subscription = null;

    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    _connection?.cancel();
    _connection = null;

    _buffer = '';
    _isConnected = false;
    if (clearQuery) {
      _currentQuery = null;
    }
  }

  /// 获取源错误信息
  @override
  Map<String, String> get sourceErrors => Map.from(_sourceErrors);

  /// 释放资源
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_disposeResources());
  }

  Future<void> _disposeResources() async {
    await _stopActiveSearch(clearQuery: true);
    await _eventController.close();
  }
}
