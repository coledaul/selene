import '../core/network/dio_authenticator.dart';
import '../core/network/moon_tv_api_client.dart';
import '../core/network/session_cookie_store.dart';
import '../features/auth/application/auth_session_controller.dart';
import '../features/auth/infrastructure/auth_profile_store.dart';
import '../features/auth/infrastructure/credential_store.dart';
import '../services/api_service.dart';
import '../services/live_service.dart';
import '../services/page_cache_service.dart';
import '../services/search_service.dart';
import '../services/sse_search_service.dart';

class AppDependencies {
  AppDependencies._({
    required this.authController,
    required this.apiClient,
    required this.apiService,
    required this.pageCacheService,
    required this.searchService,
    required this.liveService,
  });

  factory AppDependencies.create() {
    final profileStore = SharedPreferencesAuthProfileStore();
    final credentialStore = SecureCredentialStore();
    final cookieStore = SessionCookieStore();
    final authenticator = DioAuthenticator(cookieStore: cookieStore);
    final authController = AuthSessionController(
      profileStore: profileStore,
      credentialStore: credentialStore,
      authenticator: authenticator,
    );
    final apiClient = MoonTvApiClient(
      sessionController: authController,
      cookieStore: cookieStore,
    );
    final apiService = ApiService(apiClient);
    final pageCacheService = PageCacheService(apiService, authController);
    final searchService = SearchService(apiService, authController);
    final liveService = LiveService(apiService, authController);

    return AppDependencies._(
      authController: authController,
      apiClient: apiClient,
      apiService: apiService,
      pageCacheService: pageCacheService,
      searchService: searchService,
      liveService: liveService,
    );
  }

  final AuthSessionController authController;
  final MoonTvClient apiClient;
  final ApiService apiService;
  final PageCacheService pageCacheService;
  final SearchService searchService;
  final LiveService liveService;

  SSESearchService createSseSearchService() {
    return SSESearchService(
      apiService: apiService,
      client: apiClient,
      sessionController: authController,
    );
  }
}
