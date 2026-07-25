import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import '../core/network/moon_tv_api_client.dart';
import '../features/auth/application/auth_session_controller.dart';
import '../features/auth/domain/auth_models.dart';
import '../models/search_result.dart';
import '../models/search_resource.dart';
import 'user_data_service.dart';
import 'api_service.dart';
import 'downstream_service.dart';
import 'local_mode_storage_service.dart';

/// SSE 搜索服务
class SSESearchService {
  SSESearchService({
    required ApiService apiService,
    required MoonTvClient client,
    required AuthSessionController sessionController,
  })  : _apiService = apiService,
        _client = client,
        _sessionController = sessionController;

  final ApiService _apiService;
  final MoonTvClient _client;
  final AuthSessionController _sessionController;

  CancelToken? _cancelToken;
  StreamSubscription? _subscription;
  StreamController<List<SearchResult>>? _incrementalResultsController;
  StreamController<String>? _errorController;
  StreamController<SearchProgress>? _progressController;

  bool _isConnected = false;
  String? _currentQuery;
  final Map<String, String> _sourceErrors = {};
  String _buffer = ''; // 用于缓冲不完整的 UTF-8 字符
  int _completedSources = 0; // 跟踪完成的源数量
  int _totalSources = 0; // 总源数量
  Timer? _timeoutTimer; // 超时定时器

  /// 获取增量结果流
  Stream<List<SearchResult>> get incrementalResultsStream =>
      _incrementalResultsController?.stream ?? const Stream.empty();

  /// 获取错误流
  Stream<String> get errorStream =>
      _errorController?.stream ?? const Stream.empty();

  /// 获取进度流
  Stream<SearchProgress> get progressStream =>
      _progressController?.stream ?? const Stream.empty();

  /// 是否已连接
  bool get isConnected => _isConnected;

  /// 当前搜索查询
  String? get currentQuery => _currentQuery;

  /// 本地搜索
  Future<void> localSearch(String query) async {
    try {
      // 检查是否是本地模式
      final isLocalMode = _sessionController.status == AuthStatus.localMode;

      // 获取搜索资源列表
      final allResources = isLocalMode
          ? await LocalModeStorageService.getSearchSources()
          : await _apiService.getSearchResources();

      // 过滤掉被禁用的资源
      final resources =
          allResources.where((resource) => !resource.disabled).toList();

      if (resources.isEmpty) {
        _errorController?.add('没有可用的搜索资源');
        _isConnected = false;
        return;
      }

      _totalSources = resources.length;
      _completedSources = 0;

      _progressController?.add(SearchProgress(
        totalSources: _totalSources,
        completedSources: 0,
        currentSource: null,
        isComplete: false,
      ));

      // 并发调用所有资源的搜索，每个调用增加 20 秒超时
      final searchFutures = resources.map((resource) {
        return _searchSingleResource(resource, query);
      }).toList();

      // 等待所有搜索完成
      await Future.wait(searchFutures);

      // 发送完成事件
      _progressController?.add(SearchProgress(
        totalSources: _totalSources,
        completedSources: _totalSources,
        currentSource: null,
        isComplete: true,
      ));

      _isConnected = false;
    } catch (e) {
      _errorController?.add('本地搜索异常: ${e.toString()}');
      _isConnected = false;
    }
  }

  /// 搜索单个资源
  Future<void> _searchSingleResource(
      SearchResource resource, String query) async {
    try {
      // 调用 searchFromApi 并设置 20 秒超时
      final results = await DownstreamService.searchFromApi(resource, query)
          .timeout(const Duration(seconds: 20));

      // 增加完成计数
      _completedSources++;

      // 发送结果事件
      if (results.isNotEmpty) {
        _incrementalResultsController?.add(results);
      }

      // 发送进度更新
      _progressController?.add(SearchProgress(
        totalSources: _totalSources,
        completedSources: _completedSources,
        currentSource: resource.name,
        isComplete: false,
      ));
    } on TimeoutException {
      // 超时处理
      _completedSources++;
      _sourceErrors[resource.key] = '搜索超时（20秒）';

      // 发送错误进度更新
      _progressController?.add(SearchProgress(
        totalSources: _totalSources,
        completedSources: _completedSources,
        currentSource: resource.name,
        isComplete: false,
        error: '搜索超时（20秒）',
      ));
    } catch (e) {
      // 其他错误处理
      _completedSources++;
      _sourceErrors[resource.key] = e.toString();

      // 发送错误进度更新
      _progressController?.add(SearchProgress(
        totalSources: _totalSources,
        completedSources: _completedSources,
        currentSource: resource.name,
        isComplete: false,
        error: e.toString(),
      ));
    }
  }

  /// 开始搜索
  Future<void> startSearch(String query) async {
    if (query.trim().isEmpty) {
      throw Exception('搜索查询不能为空');
    }

    // 如果已有连接，先关闭
    if (_isConnected) {
      await stopSearch();
    }

    // 关闭之前的流控制器
    await _incrementalResultsController?.close();
    await _errorController?.close();
    await _progressController?.close();

    _currentQuery = query.trim();
    _sourceErrors.clear();
    _completedSources = 0;

    // 初始化流控制器
    _incrementalResultsController =
        StreamController<List<SearchResult>>.broadcast();
    _errorController = StreamController<String>.broadcast();
    _progressController = StreamController<SearchProgress>.broadcast();

    _isConnected = true;

    // 设置15秒超时定时器
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (_isConnected) {
        _handleTimeout();
      }
    });

    // 检查是否启用本地搜索或本地模式
    final isLocalMode = _sessionController.status == AuthStatus.localMode;
    if (isLocalMode) {
      localSearch(query);
      return;
    }

    final isLocalSearch = await UserDataService.getLocalSearch();
    if (isLocalSearch) {
      localSearch(query);
      return;
    }

    try {
      _cancelToken = CancelToken();
      final response = await _client.request(
        '/api/search/ws',
        queryParameters: <String, dynamic>{'q': _currentQuery!},
        headers: const <String, String>{
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
        responseType: ResponseType.stream,
        cancelToken: _cancelToken,
      );
      final body = response.data;
      if (body is! ResponseBody) {
        throw const FormatException('服务器未返回有效的 SSE 数据流');
      }

      _buffer = '';
      _subscription =
          body.stream.cast<List<int>>().transform(utf8.decoder).listen(
        _handleSSEChunk,
        onError: (error) {
          // 静默处理连接关闭错误，不显示给用户
          final errorString = error.toString().toLowerCase();
          if (errorString.contains('connection closed') ||
              errorString.contains('clientexception') ||
              errorString.contains('connection terminated')) {
            // 连接被关闭，这是正常情况，静默处理
            return;
          }
          _handleError(error);
        },
        onDone: _handleDone,
      );
    } catch (e) {
      _isConnected = false;

      // 检查是否是连接关闭错误，如果是则静默处理
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('connection closed') ||
          errorString.contains('clientexception') ||
          errorString.contains('connection terminated')) {
        // 连接被关闭，这是正常情况，静默处理
        return;
      }

      _errorController?.add('连接失败: ${e.toString()}');
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
      final normalized = line.trimRight();
      if (normalized.startsWith('data: ')) {
        _handleSSEData(normalized.substring(6));
      }
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
      _errorController?.add('消息解析失败: ${e.toString()}');
    }
  }

  /// 处理开始事件
  void _handleStartEvent(SearchStartEvent event) {
    _totalSources = event.totalSources;
    _progressController?.add(SearchProgress(
      totalSources: event.totalSources,
      completedSources: 0,
      currentSource: null,
      isComplete: false,
    ));
  }

  /// 处理搜索结果事件
  void _handleSourceResultEvent(SearchSourceResultEvent event) {
    _completedSources++;

    // 只发送增量结果更新，避免全量重渲染
    if (event.results.isNotEmpty) {
      _incrementalResultsController?.add(List.from(event.results));
    }

    // 更新进度（无论是否有结果都要更新）
    _progressController?.add(SearchProgress(
      totalSources: _totalSources,
      completedSources: _completedSources,
      currentSource: event.sourceName,
      isComplete: false,
    ));
  }

  /// 处理搜索错误事件
  void _handleSourceErrorEvent(SearchSourceErrorEvent event) {
    _sourceErrors[event.source] = event.error;

    // 错误也算源完成，累计进度
    _completedSources++;

    // 更新进度
    _progressController?.add(SearchProgress(
      totalSources: _totalSources,
      completedSources: _completedSources,
      currentSource: event.sourceName,
      isComplete: false,
      error: event.error,
    ));
  }

  /// 处理完成事件
  void _handleCompleteEvent(SearchCompleteEvent event) {
    // 如果完成源数小于总源数，说明有些源没有发送结果事件
    // 将完成源数设置为总源数
    if (_completedSources < _totalSources) {
      _completedSources = _totalSources;
    }

    // 发送最终完成状态
    _progressController?.add(SearchProgress(
      totalSources: _totalSources,
      completedSources: _completedSources,
      currentSource: null,
      isComplete: true,
    ));

    // 搜索完成，关闭连接
    _closeConnection();
  }

  /// 处理超时
  void _handleTimeout() {
    // 如果完成源数小于总源数，说明有些源没有发送结果事件
    // 将完成源数设置为总源数
    if (_completedSources < _totalSources) {
      _completedSources = _totalSources;
    }

    // 发送超时状态
    _progressController?.add(SearchProgress(
      totalSources: _totalSources,
      completedSources: _completedSources,
      currentSource: null,
      isComplete: true,
    ));

    _errorController?.add('搜索超时（15秒）');
    _closeConnection();
  }

  /// 关闭连接
  void _closeConnection() {
    _isConnected = false;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _cancelToken?.cancel('搜索已停止');
    _cancelToken = null;
  }

  /// 处理 SSE 错误
  void _handleError(error) {
    _isConnected = false;

    // 检查是否是连接关闭错误，如果是则忽略
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('connection closed') ||
        errorString.contains('clientexception') ||
        errorString.contains('connection terminated')) {
      // 连接被关闭，这是正常情况，不显示错误
      print('搜索连接已关闭: ${error.toString()}');
      return;
    }

    // 其他错误才显示给用户
    _errorController?.add('SSE 错误: ${error.toString()}');
  }

  /// 处理 SSE 关闭
  void _handleDone() {
    _isConnected = false;
  }

  /// 停止搜索
  Future<void> stopSearch() async {
    await _subscription?.cancel();
    _subscription = null;

    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    _cancelToken?.cancel('搜索已停止');
    _cancelToken = null;

    _isConnected = false;
    _currentQuery = null;

    // 关闭流控制器
    await _incrementalResultsController?.close();
    await _errorController?.close();
    await _progressController?.close();

    _incrementalResultsController = null;
    _errorController = null;
    _progressController = null;
  }

  /// 获取源错误信息
  Map<String, String> get sourceErrors => Map.from(_sourceErrors);

  /// 释放资源
  void dispose() {
    stopSearch();
  }
}

/// 搜索进度信息
class SearchProgress {
  final int totalSources;
  final int completedSources;
  final String? currentSource;
  final bool isComplete;
  final String? error;

  SearchProgress({
    required this.totalSources,
    required this.completedSources,
    this.currentSource,
    required this.isComplete,
    this.error,
  });

  /// 获取完成百分比
  double get progressPercentage {
    if (totalSources <= 0) return 0.0;
    return (completedSources / totalSources).clamp(0.0, 1.0);
  }

  /// 是否有错误
  bool get hasError => error != null;

  /// 获取进度描述
  String get progressDescription {
    if (isComplete) {
      return '搜索完成';
    } else if (currentSource != null) {
      return '正在搜索: $currentSource';
    } else {
      return '准备搜索...';
    }
  }
}
