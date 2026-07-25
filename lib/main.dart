import 'dart:async';
import 'dart:io' show Platform;

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:macos_window_utils/macos_window_utils.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

import 'app/app_dependencies.dart';
import 'features/auth/application/auth_session_controller.dart';
import 'features/auth/domain/auth_models.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/video_download/application/video_download_manager.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'services/douban_cache_service.dart';
import 'services/live_service.dart';
import 'services/local_mode_storage_service.dart';
import 'services/page_cache_service.dart';
import 'services/search_service.dart';
import 'services/subscription_service.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  if (Platform.isMacOS) {
    await WindowManipulator.initialize(enableWindowDelegate: true);
    await WindowManipulator.makeTitlebarTransparent();
    await WindowManipulator.enableFullSizeContentView();
    await WindowManipulator.hideTitle();
  }

  final doubanCacheService = DoubanCacheService();
  await doubanCacheService.init();
  doubanCacheService.startPeriodicCleanup();

  final dependencies = AppDependencies.create();
  runApp(SeleneApp(dependencies: dependencies));

  if (Platform.isWindows) {
    doWhenWindowReady(() {
      final window = appWindow;
      const initialSize = Size(1024, 600);
      const minSize = Size(1024, 600);
      window.minSize = minSize;
      window.size = initialSize;
      window.alignment = Alignment.center;
      window.title = 'Selene';
      window.show();
    });
  }
}

class SeleneApp extends StatelessWidget {
  const SeleneApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider<AuthSessionController>.value(
          value: dependencies.authController,
        ),
        Provider<AppDependencies>.value(value: dependencies),
        Provider<ApiService>.value(value: dependencies.apiService),
        Provider<PageCacheService>.value(value: dependencies.pageCacheService),
        Provider<SearchService>.value(value: dependencies.searchService),
        Provider<LiveService>.value(value: dependencies.liveService),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) {
            final manager = VideoDownloadManager();
            unawaited(
              manager.initialize().catchError((Object error, StackTrace stack) {
                debugPrint('VideoDownloadManager initialization failed');
              }),
            );
            return manager;
          },
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Selene',
            debugShowCheckedModeBanner: false,
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.themeMode,
            home: const AppWrapper(),
            builder: (context, child) {
              if (Platform.isWindows) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1),
                  ),
                  child: child!,
                );
              }
              return child!;
            },
          );
        },
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  AuthSessionController? _authController;
  bool _localRefreshStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_authController != null) {
      return;
    }
    _authController = context.read<AuthSessionController>()
      ..addListener(_handleAuthStateChanged);
    unawaited(_authController!.initialize());
  }

  void _handleAuthStateChanged() {
    if (_authController?.status != AuthStatus.localMode) {
      _localRefreshStarted = false;
      return;
    }
    if (_localRefreshStarted) {
      return;
    }
    _localRefreshStarted = true;
    unawaited(_refreshLocalSubscription());
  }

  Future<void> _refreshLocalSubscription() async {
    try {
      final subscriptionUrl =
          await LocalModeStorageService.getSubscriptionUrl();
      if (subscriptionUrl == null || subscriptionUrl.isEmpty) {
        return;
      }
      final response = await http.get(Uri.parse(subscriptionUrl));
      if (response.statusCode != 200) {
        return;
      }
      final content =
          await SubscriptionService.parseSubscriptionContent(response.body);
      if (content == null) {
        return;
      }
      if (content.searchResources?.isNotEmpty ?? false) {
        await LocalModeStorageService.saveSearchSources(
          content.searchResources!,
        );
      }
      if (content.liveSources?.isNotEmpty ?? false) {
        await LocalModeStorageService.saveLiveSources(content.liveSources!);
      }
    } catch (_) {
      // 本地订阅刷新失败不阻塞进入首页。
    }
  }

  @override
  void dispose() {
    _authController?.removeListener(_handleAuthStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const AuthGate(
      authenticated: HomeScreen(),
      localMode: HomeScreen(),
      unauthenticated: LoginScreen(),
      loading: _AuthenticationLoadingScreen(),
    );
  }
}

class _AuthenticationLoadingScreen extends StatelessWidget {
  const _AuthenticationLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              color: themeService.isDarkMode ? Colors.black : null,
              gradient: themeService.isDarkMode
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFe6f3fb),
                        Color(0xFFeaf3f7),
                        Color(0xFFf7f7f3),
                        Color(0xFFe9ecef),
                        Color(0xFFdbe3ea),
                        Color(0xFFd3dde6),
                      ],
                      stops: [0, 0.18, 0.38, 0.60, 0.80, 1],
                    ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      themeService.isDarkMode
                          ? Colors.white
                          : const Color(0xFF2c3e50),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '正在检查登录状态...',
                    style: TextStyle(
                      fontSize: 16,
                      color: themeService.isDarkMode
                          ? Colors.white
                          : const Color(0xFF2c3e50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
