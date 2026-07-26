import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MVVM dependency rules', () {
    test('legacy source directories are removed', () {
      const legacyDirectories = <String>[
        'lib/features',
        'lib/models',
        'lib/screens',
        'lib/services',
        'lib/widgets',
      ];
      final remaining = legacyDirectories
          .where((path) => Directory(path).existsSync())
          .toList(growable: false);

      expect(remaining, isEmpty, reason: remaining.join('\n'));
    });

    test('UI widgets cannot import data or legacy services', () {
      final violations = _importsMatching(
        root: Directory('lib/ui'),
        filePathContains:
            '${Platform.pathSeparator}widgets${Platform.pathSeparator}',
        forbidden: const <String>['/data/', '/services/'],
      );

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test(
      'ViewModels cannot depend on widgets, routing, or service implementations',
      () {
        final violations = _importsMatching(
          root: Directory('lib/ui'),
          filePathContains:
              '${Platform.pathSeparator}view_models${Platform.pathSeparator}',
          forbidden: const <String>[
            'package:flutter/material.dart',
            '/widgets/',
            '/routing/',
            '/data/services/',
            '_repository_impl.dart',
          ],
        );

        expect(violations, isEmpty, reason: violations.join('\n'));
      },
    );

    test('Data layer never imports UI or routing', () {
      final violations = _importsMatching(
        root: Directory('lib/data'),
        forbidden: const <String>['/ui/', '/routing/'],
      );

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('Services never import repositories, UI, or routing', () {
      final violations = _importsMatching(
        root: Directory('lib/data/services'),
        forbidden: const <String>['/repositories/', '/ui/', '/routing/'],
      );

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('Repositories cannot import sibling repositories', () {
      final violations = _repositoryImportViolations();

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('Repositories cannot depend directly on HTTP client packages', () {
      final violations = _importsMatching(
        root: Directory('lib/data/repositories'),
        forbidden: const <String>['package:http/', 'package:dio/'],
      );

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('Repositories cannot call static service implementations', () {
      final violations = _sourcePatternViolations(
        root: Directory('lib/data/repositories'),
        pattern: RegExp(r'\b[A-Z][A-Za-z0-9]*Service\.'),
      );

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test(
      'Stateful pages never dispose ViewModels borrowed from Widget fields',
      () {
        final violations = _widgetViewModelDisposalViolations();

        expect(violations, isEmpty, reason: violations.join('\n'));
      },
    );

    test('Route-owned ViewModels are supplied as factories', () {
      const requirements = <String, List<String>>{
        'lib/ui/home/widgets/home_screen.dart': <String>[
          'HomeViewModel Function() homeViewModelFactory',
        ],
        'lib/ui/auth/widgets/login_screen.dart': <String>[
          'LoginViewModel Function() viewModelFactory',
        ],
        'lib/ui/downloads/widgets/download_manager_screen.dart': <String>[
          'DownloadViewModel Function() viewModelFactory',
        ],
        'lib/ui/player/widgets/player_screen.dart': <String>[
          'PlayerViewModel Function() viewModelFactory',
        ],
        'lib/ui/live/widgets/live_player_screen.dart': <String>[
          'LivePlayerViewModel Function() viewModelFactory',
        ],
        'lib/ui/search/widgets/search_screen.dart': <String>[
          'SearchViewModel Function() viewModelFactory',
          'ShellViewModel Function() shellViewModelFactory',
        ],
      };
      final violations = <String>[];
      for (final entry in requirements.entries) {
        final source = File(entry.key).readAsStringSync();
        for (final requirement in entry.value) {
          if (!source.contains(requirement)) {
            violations.add('${entry.key}: missing $requirement');
          }
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('All UI ViewModels share the lifecycle-aware base class', () {
      final violations = <String>[];
      for (final entity in Directory('lib/ui').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('_view_model.dart')) {
          continue;
        }
        final source = entity.readAsStringSync();
        if (source.contains('extends ChangeNotifier')) {
          violations.add('${entity.path}: bypasses ViewModel');
        }
        if (!entity.path.endsWith('${Platform.pathSeparator}view_model.dart') &&
            source.contains('notifyListeners()')) {
          violations.add('${entity.path}: bypasses lifecycle notification');
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test(
      'Player screen delegates initial business orchestration to ViewModel',
      () {
        final source = File(
          'lib/ui/player/widgets/player_screen.dart',
        ).readAsStringSync();

        expect(source, contains('_viewModel.load('));
        expect(source, isNot(contains('getPreferSpeedTest(')));
        expect(source, isNot(contains('getResume(')));
        expect(source, isNot(contains('searchSources(')));
      },
    );

    test('Declared SDK floor matches generated dependency requirements', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(pubspec, contains("sdk: '>=3.12.0 <4.0.0'"));
      expect(pubspec, contains("flutter: '>=3.44.0'"));
    });

    test('Only composition code imports concrete data implementations', () {
      final violations = _importsMatching(
        root: Directory('lib/ui'),
        forbidden: const <String>[
          '/data/services/',
          'DefaultAuthRepository',
          'DefaultSubscriptionRepository',
        ],
      );

      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test(
      'Composition root owns session coordination and app-level resources',
      () {
        final source = File('lib/app/app_dependencies.dart').readAsStringSync();

        expect(source, contains('_sessionCacheCoordinator.start();'));
        expect(source, contains('_sessionCacheCoordinator.dispose();'));
        expect(source, contains('subscriptionRepository.dispose();'));
        expect(source, contains('updateRepository.dispose();'));
        expect(source, contains('invalidateCaches: () {'));
        expect(source, contains('searchRepository.clearCache();'));
        expect(source, contains('localSearchCacheService.clearCache();'));
      },
    );

    test(
      'Session changes invalidate only identity-sensitive content cache',
      () {
        final source = File(
          'lib/app/session_cache_coordinator.dart',
        ).readAsStringSync();

        expect(source, contains('_cacheRepository.clearSearchCache'));
        expect(source, isNot(contains('clearCatalogAndSearch')));
      },
    );
  });
}

List<String> _widgetViewModelDisposalViolations() {
  final violations = <String>[];
  final pattern = RegExp(
    r'widget\.(?:viewModel|shellViewModel)(?:(?!;)[\s\S])*?(?:\.\.|\.)dispose\(\);',
  );
  for (final entity in Directory('lib/ui').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (!entity.path.endsWith('_screen.dart')) continue;
    if (pattern.hasMatch(entity.readAsStringSync())) {
      violations.add(entity.path);
    }
  }
  return violations;
}

List<String> _repositoryImportViolations() {
  final violations = <String>[];
  final root = Directory('lib/data/repositories');
  for (final entity in root.listSync()) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final fileName = entity.uri.pathSegments.last;
    final lines = entity.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index].trim();
      if (!line.startsWith('import ') || !line.contains('_repository.dart')) {
        continue;
      }
      final isImplementationPair =
          fileName == 'default_download_repository.dart' &&
          line.contains("'download_repository.dart'");
      if (!isImplementationPair) {
        violations.add('${entity.path}:${index + 1}: $line');
      }
    }
  }
  return violations;
}

List<String> _sourcePatternViolations({
  required Directory root,
  required RegExp pattern,
}) {
  final violations = <String>[];
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final lines = entity.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      if (pattern.hasMatch(lines[index])) {
        violations.add('${entity.path}:${index + 1}: ${lines[index].trim()}');
      }
    }
  }
  return violations;
}

List<String> _importsMatching({
  required Directory root,
  String? filePathContains,
  required List<String> forbidden,
}) {
  if (!root.existsSync()) {
    return <String>[];
  }

  final violations = <String>[];
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    if (filePathContains != null && !entity.path.contains(filePathContains)) {
      continue;
    }
    final lines = entity.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index].trim();
      if (!line.startsWith('import ')) {
        continue;
      }
      if (forbidden.any(line.contains)) {
        violations.add('${entity.path}:${index + 1}: $line');
      }
    }
  }
  return violations;
}
