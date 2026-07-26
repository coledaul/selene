import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/app_dependencies.dart';
import '../ui/home/widgets/home_screen.dart';
import '../ui/auth/view_models/login_view_model.dart';
import '../ui/auth/widgets/auth_loading_screen.dart';
import '../ui/auth/widgets/login_screen.dart';
import '../ui/home/view_models/home_view_model.dart';
import '../ui/catalog/view_models/catalog_view_model.dart';
import '../ui/catalog/view_models/anime_view_model.dart';
import '../ui/search/view_models/search_view_model.dart';
import '../ui/live/view_models/live_view_model.dart';
import '../ui/live/view_models/live_player_view_model.dart';
import '../ui/settings/view_models/settings_view_model.dart';
import '../ui/shell/view_models/shell_view_model.dart';
import '../ui/downloads/view_models/download_view_model.dart';
import '../ui/downloads/widgets/download_manager_screen.dart';
import '../ui/player/widgets/player_screen.dart';
import '../ui/player/view_models/player_view_model.dart';

part 'routes.g.dart';

NoTransitionPage<void> buildSessionRootPage({
  required LocalKey key,
  required Widget child,
}) => NoTransitionPage<void>(key: key, child: child);

@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSessionRootPage(key: state.pageKey, child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final dependencies = context.read<AppDependencies>();
    return HomeScreen(
      homeViewModelFactory: () => HomeViewModel(
        libraryRepository: dependencies.libraryRepository,
        catalogRepository: dependencies.catalogRepository,
        animeRepository: dependencies.animeRepository,
        updateRepository: dependencies.updateRepository,
      ),
      settingsViewModelFactory: () => SettingsViewModel(
        authRepository: dependencies.authRepository,
        settingsRepository: dependencies.settingsRepository,
        updateRepository: dependencies.updateRepository,
        cacheRepository: dependencies.cacheRepository,
        libraryRepository: dependencies.libraryRepository,
        liveRepository: dependencies.liveRepository,
      ),
      searchViewModelFactory: () => SearchViewModel(
        libraryRepository: dependencies.libraryRepository,
        searchSession: dependencies.createSseSearchRepository(),
        settingsRepository: dependencies.settingsRepository,
      ),
      liveViewModelFactory: () =>
          LiveViewModel(repository: dependencies.liveRepository),
      livePlayerViewModelFactory: (channel, source) => LivePlayerViewModel(
        repository: dependencies.liveRepository,
        channel: channel,
        source: source,
      ),
      catalogViewModelFactory: (definition) => CatalogViewModel(
        repository: dependencies.catalogRepository,
        definition: definition,
      ),
      animeViewModelFactory: () =>
          AnimeViewModel(repository: dependencies.animeRepository),
      shellViewModelFactory: () => ShellViewModel(
        searchRepository: dependencies.searchRepository,
        settingsRepository: dependencies.settingsRepository,
      ),
    );
  }
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSessionRootPage(key: state.pageKey, child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final dependencies = context.read<AppDependencies>();
    return LoginScreen(
      viewModelFactory: () => LoginViewModel(
        authRepository: dependencies.authRepository,
        subscriptionRepository: dependencies.subscriptionRepository,
      ),
    );
  }
}

@TypedGoRoute<AuthLoadingRoute>(path: '/loading')
class AuthLoadingRoute extends GoRouteData with $AuthLoadingRoute {
  const AuthLoadingRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      buildSessionRootPage(key: state.pageKey, child: build(context, state));

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AuthLoadingScreen();
  }
}

@TypedGoRoute<DownloadsRoute>(path: '/downloads')
class DownloadsRoute extends GoRouteData with $DownloadsRoute {
  const DownloadsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final dependencies = context.read<AppDependencies>();
    return DownloadManagerScreen(
      viewModelFactory: () =>
          DownloadViewModel(repository: dependencies.downloadRepository),
    );
  }
}

@TypedGoRoute<PlayerRoute>(path: '/player')
class PlayerRoute extends GoRouteData with $PlayerRoute {
  const PlayerRoute({
    required this.title,
    this.source,
    this.id,
    this.year,
    this.stitle,
    this.stype,
    this.prefer,
  });

  final String title;
  final String? source;
  final String? id;
  final String? year;
  final String? stitle;
  final String? stype;
  final String? prefer;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final dependencies = context.read<AppDependencies>();
    return PlayerScreen(
      viewModelFactory: () => PlayerViewModel(
        repository: dependencies.playerRepository,
        downloadRepository: dependencies.downloadRepository,
        searchRepository: dependencies.searchRepository,
        settingsRepository: dependencies.settingsRepository,
        libraryRepository: dependencies.libraryRepository,
        sessionState: dependencies.authRepository,
      ),
      title: title,
      source: source,
      id: id,
      year: year,
      stitle: stitle,
      stype: stype,
      prefer: prefer,
    );
  }
}
