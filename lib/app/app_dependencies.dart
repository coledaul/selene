import 'dart:async';

import 'session_cache_coordinator.dart';
import '../data/services/dio_auth_api_service.dart';
import '../data/services/moon_tv_api_service.dart';
import '../data/services/session_cookie_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/anime_repository.dart';
import '../data/repositories/cache_repository.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/download_repository.dart';
import '../data/repositories/player_repository.dart';
import '../data/repositories/metadata_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/subscription_repository.dart';
import '../data/repositories/theme_repository.dart';
import '../data/repositories/update_repository.dart';
import '../data/services/auth_profile_service.dart';
import '../data/services/credential_service.dart';
import '../data/services/settings_preferences_service.dart';
import '../data/services/search_stream_service.dart';
import '../data/services/subscription_api_service.dart';
import '../data/services/subscription_local_service.dart';
import '../data/services/window_appearance_service.dart';
import '../data/services/update_api_service.dart';
import '../data/services/update_preferences_service.dart';
import '../data/services/api_service.dart';
import '../data/services/douban_cache_service.dart';
import '../data/services/local_search_cache_service.dart';
import '../data/repositories/live_repository.dart';
import '../data/repositories/library_repository.dart';
import '../data/repositories/search_repository.dart';
import '../data/repositories/sse_search_repository.dart';
import '../data/repositories/default_download_repository.dart';
import '../utils/app_logger.dart';

class AppDependencies {
  AppDependencies._({
    required this.authRepository,
    required this.animeRepository,
    required this.subscriptionRepository,
    required this.themeRepository,
    required this.updateRepository,
    required this.settingsRepository,
    required this.cacheRepository,
    required this.catalogRepository,
    required this.downloadRepository,
    required this.playerRepository,
    required this.metadataRepository,
    required MoonTvClient apiClient,
    required ApiService apiService,
    required this.libraryRepository,
    required this.searchRepository,
    required this.liveRepository,
    required SessionCacheCoordinator sessionCacheCoordinator,
  }) : _apiClient = apiClient,
       _apiService = apiService,
       _sessionCacheCoordinator = sessionCacheCoordinator;

  factory AppDependencies.create({
    required DoubanCacheService doubanCacheService,
  }) {
    final profileStore = SharedPreferencesAuthProfileStore();
    final credentialStore = SecureCredentialStore();
    final cookieStore = SessionCookieService();
    final authenticator = DioAuthApiService(cookieStore: cookieStore);
    final authRepository = DefaultAuthRepository(
      profileStore: profileStore,
      credentialStore: credentialStore,
      authenticator: authenticator,
    );
    final animeRepository = DefaultAnimeRepository();
    final apiClient = MoonTvApiClient(
      sessionController: authRepository,
      cookieStore: cookieStore,
    );
    final apiService = ApiService(apiClient);
    final libraryRepository = DefaultLibraryRepository(
      apiService: apiService,
      sessionState: authRepository,
    );
    final liveRepository = DefaultLiveRepository(
      apiService: apiService,
      sessionState: authRepository,
    );
    final searchRepository = DefaultSearchRepository(
      apiService: apiService,
      sessionState: authRepository,
    );
    final localSearchCacheService = LocalSearchCacheService();
    final subscriptionRepository = DefaultSubscriptionRepository(
      apiService: DioSubscriptionApiService(),
      localService: SharedPreferencesSubscriptionLocalService(),
      invalidateCaches: () {
        searchRepository.clearCache();
        localSearchCacheService.clearCache();
      },
    );
    final themeRepository = DefaultThemeRepository(
      windowService: MacOsWindowAppearanceService(),
    );
    final updateRepository = DefaultUpdateRepository(
      apiService: GitHubUpdateApiService(),
      preferencesService: SharedPreferencesUpdateService(),
    );
    final settingsRepository = DefaultSettingsRepository(
      service: SharedPreferencesSettingsService(),
    );
    final cacheRepository = DefaultCacheRepository(
      doubanCacheService: doubanCacheService,
      localSearchCacheService: localSearchCacheService,
    );
    final catalogRepository = DefaultCatalogRepository();
    final downloadRepository = DefaultDownloadRepository();
    final playerRepository = DefaultPlayerRepository(apiService: apiService);
    final metadataRepository = DefaultMetadataRepository();
    final sessionCacheCoordinator = SessionCacheCoordinator(
      authRepository: authRepository,
      libraryRepository: libraryRepository,
      liveRepository: liveRepository,
      searchRepository: searchRepository,
      cacheRepository: cacheRepository,
      subscriptionRepository: subscriptionRepository,
    );

    return AppDependencies._(
      authRepository: authRepository,
      animeRepository: animeRepository,
      subscriptionRepository: subscriptionRepository,
      themeRepository: themeRepository,
      updateRepository: updateRepository,
      settingsRepository: settingsRepository,
      cacheRepository: cacheRepository,
      catalogRepository: catalogRepository,
      downloadRepository: downloadRepository,
      playerRepository: playerRepository,
      metadataRepository: metadataRepository,
      apiClient: apiClient,
      apiService: apiService,
      libraryRepository: libraryRepository,
      searchRepository: searchRepository,
      liveRepository: liveRepository,
      sessionCacheCoordinator: sessionCacheCoordinator,
    );
  }

  final AuthRepository authRepository;
  final AnimeRepository animeRepository;
  final SubscriptionRepository subscriptionRepository;
  final ThemeRepository themeRepository;
  final UpdateRepository updateRepository;
  final SettingsRepository settingsRepository;
  final CacheRepository cacheRepository;
  final CatalogRepository catalogRepository;
  final DownloadRepository downloadRepository;
  final PlayerRepository playerRepository;
  final MetadataRepository metadataRepository;
  final MoonTvClient _apiClient;
  final ApiService _apiService;
  final LibraryRepository libraryRepository;
  final SearchRepository searchRepository;
  final LiveRepository liveRepository;
  final SessionCacheCoordinator _sessionCacheCoordinator;

  SSESearchRepository createSseSearchRepository() {
    return DefaultSSESearchRepository(
      apiService: _apiService,
      streamService: DefaultSearchStreamService(_apiClient),
      sessionState: authRepository,
    );
  }

  void start() {
    _sessionCacheCoordinator.start();
    unawaited(authRepository.initialize());
    unawaited(
      downloadRepository.initialize().catchError((
        Object error,
        StackTrace stack,
      ) {
        AppLogger.debug('下载任务初始化失败', error: error, stackTrace: stack);
      }),
    );
  }

  void dispose() {
    _sessionCacheCoordinator.dispose();
    authRepository.dispose();
    _apiClient.dispose();
    subscriptionRepository.dispose();
    updateRepository.dispose();
    themeRepository.dispose();
    cacheRepository.dispose();
    playerRepository.dispose();
    downloadRepository.dispose();
  }
}
