import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routing/app_router.dart';
import '../domain/models/app_theme_mode.dart';
import '../ui/core/themes/app_theme.dart';
import '../ui/core/view_models/theme_view_model.dart';
import '../ui/core/view_models/video_metadata_view_model.dart';
import '../ui/core/widgets/video_metadata_scope.dart';
import 'app_dependencies.dart';

class SeleneApp extends StatefulWidget {
  const SeleneApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<SeleneApp> createState() => _SeleneAppState();
}

class _SeleneAppState extends State<SeleneApp> {
  late final AppRouter _router = AppRouter(widget.dependencies.authRepository);

  @override
  void dispose() {
    _router.config.dispose();
    widget.dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              ThemeViewModel(repository: dependencies.themeRepository),
        ),
        Provider<AppDependencies>.value(value: dependencies),
      ],
      child: VideoMetadataScope(
        create: () =>
            VideoMetadataViewModel(repository: dependencies.metadataRepository),
        child: Consumer<ThemeViewModel>(
          builder: (context, themeService, child) {
            return MaterialApp.router(
              title: 'Selene',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: switch (themeService.mode) {
                AppThemeMode.system => ThemeMode.system,
                AppThemeMode.light => ThemeMode.light,
                AppThemeMode.dark => ThemeMode.dark,
              },
              routerConfig: _router.config,
              builder: (context, child) {
                if (!Platform.isWindows) {
                  return child!;
                }
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1)),
                  child: child!,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
