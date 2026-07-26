// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $homeRoute,
  $loginRoute,
  $authLoadingRoute,
  $downloadsRoute,
  $playerRoute,
];

RouteBase get $homeRoute => GoRouteData.$route(
  path: '/',
  hasOverriddenOnExit: false,
  factory: $HomeRoute._fromState,
);

mixin $HomeRoute on GoRouteData {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $loginRoute => GoRouteData.$route(
  path: '/login',
  hasOverriddenOnExit: false,
  factory: $LoginRoute._fromState,
);

mixin $LoginRoute on GoRouteData {
  static LoginRoute _fromState(GoRouterState state) => const LoginRoute();

  @override
  String get location => GoRouteData.$location('/login');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $authLoadingRoute => GoRouteData.$route(
  path: '/loading',
  hasOverriddenOnExit: false,
  factory: $AuthLoadingRoute._fromState,
);

mixin $AuthLoadingRoute on GoRouteData {
  static AuthLoadingRoute _fromState(GoRouterState state) =>
      const AuthLoadingRoute();

  @override
  String get location => GoRouteData.$location('/loading');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $downloadsRoute => GoRouteData.$route(
  path: '/downloads',
  hasOverriddenOnExit: false,
  factory: $DownloadsRoute._fromState,
);

mixin $DownloadsRoute on GoRouteData {
  static DownloadsRoute _fromState(GoRouterState state) =>
      const DownloadsRoute();

  @override
  String get location => GoRouteData.$location('/downloads');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $playerRoute => GoRouteData.$route(
  path: '/player',
  hasOverriddenOnExit: false,
  factory: $PlayerRoute._fromState,
);

mixin $PlayerRoute on GoRouteData {
  static PlayerRoute _fromState(GoRouterState state) => PlayerRoute(
    title: state.uri.queryParameters['title']!,
    source: state.uri.queryParameters['source'],
    id: state.uri.queryParameters['id'],
    year: state.uri.queryParameters['year'],
    stitle: state.uri.queryParameters['stitle'],
    stype: state.uri.queryParameters['stype'],
    prefer: state.uri.queryParameters['prefer'],
  );

  PlayerRoute get _self => this as PlayerRoute;

  @override
  String get location => GoRouteData.$location(
    '/player',
    queryParams: {
      'title': _self.title,
      if (_self.source != null) 'source': _self.source,
      if (_self.id != null) 'id': _self.id,
      if (_self.year != null) 'year': _self.year,
      if (_self.stitle != null) 'stitle': _self.stitle,
      if (_self.stype != null) 'stype': _self.stype,
      if (_self.prefer != null) 'prefer': _self.prefer,
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
