import 'dart:async';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/cache_repository.dart';
import '../data/repositories/library_repository.dart';
import '../data/repositories/live_repository.dart';
import '../data/repositories/search_repository.dart';
import '../data/repositories/subscription_repository.dart';
import '../domain/models/auth_models.dart';
import '../utils/app_logger.dart';

typedef _SessionIdentity = ({
  AuthStatus status,
  String serverUrl,
  String username,
  String role,
});

/// 统一维护鉴权身份与会话级缓存的生命周期边界。
final class SessionCacheCoordinator {
  SessionCacheCoordinator({
    required AuthRepository authRepository,
    required LibraryRepository libraryRepository,
    required LiveRepository liveRepository,
    required SearchRepository searchRepository,
    required CacheRepository cacheRepository,
    required SubscriptionRepository subscriptionRepository,
  }) : _authRepository = authRepository,
       _libraryRepository = libraryRepository,
       _liveRepository = liveRepository,
       _searchRepository = searchRepository,
       _cacheRepository = cacheRepository,
       _subscriptionRepository = subscriptionRepository;

  final AuthRepository _authRepository;
  final LibraryRepository _libraryRepository;
  final LiveRepository _liveRepository;
  final SearchRepository _searchRepository;
  final CacheRepository _cacheRepository;
  final SubscriptionRepository _subscriptionRepository;

  _SessionIdentity? _identity;
  bool _started = false;
  bool _disposed = false;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _identity = _currentIdentity;
    _authRepository.addListener(_handleSessionChanged);
  }

  void _handleSessionChanged() {
    if (_disposed) return;
    final previous = _identity;
    final current = _currentIdentity;
    if (current == previous) return;
    _identity = current;

    _clearSessionCaches();
    if (current.status == AuthStatus.localMode &&
        previous?.status != AuthStatus.localMode) {
      unawaited(_refreshSubscription());
    }
  }

  _SessionIdentity get _currentIdentity => (
    status: _authRepository.status,
    serverUrl: _authRepository.profile.serverUrl,
    username: _authRepository.profile.username,
    role: _authRepository.role,
  );

  void _clearSessionCaches() {
    _clearSynchronously('资料库缓存', _libraryRepository.clearAllCache);
    _clearSynchronously('直播缓存', _liveRepository.clearAllCache);
    _clearSynchronously('搜索源缓存', _searchRepository.clearCache);
    _clearSynchronously('本地搜索缓存', _cacheRepository.clearSearchCache);
  }

  void _clearSynchronously(String label, void Function() clear) {
    try {
      clear();
    } catch (error) {
      AppLogger.debug('$label清理失败：${error.runtimeType}');
    }
  }

  Future<void> _refreshSubscription() async {
    try {
      final result = await _subscriptionRepository.refresh();
      if (result.isFailure) {
        AppLogger.debug('本地订阅刷新失败');
      }
    } catch (error) {
      AppLogger.debug('本地订阅刷新异常：${error.runtimeType}');
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (_started) {
      _authRepository.removeListener(_handleSessionChanged);
    }
  }
}
