import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/search_repository.dart';
import 'package:selene/data/repositories/settings_repository.dart';
import 'package:selene/domain/models/app_settings.dart';
import 'package:selene/domain/models/search_result.dart';
import 'package:selene/ui/shell/view_models/shell_view_model.dart';
import 'package:selene/utils/result.dart';

void main() {
  test('搜索建议防抖且过期响应不会覆盖最新查询', () async {
    final repository = _FakeSearchRepository();
    final viewModel = ShellViewModel(
      searchRepository: repository,
      settingsRepository: _FakeSettingsRepository(),
      debounceDuration: Duration.zero,
    );

    viewModel.updateQuery('旧查询');
    await Future<void>.delayed(Duration.zero);
    viewModel.updateQuery('新查询');
    await Future<void>.delayed(Duration.zero);
    repository.complete('新查询', <String>['新结果']);
    await Future<void>.delayed(Duration.zero);
    repository.complete('旧查询', <String>['旧结果']);
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.state.suggestions, <String>['新结果']);
    expect(repository.queries, <String>['旧查询', '新查询']);
    viewModel.dispose();
  });

  test('搜索建议保持原有最多八条的显示上限', () async {
    final repository = _FakeSearchRepository();
    final viewModel = ShellViewModel(
      searchRepository: repository,
      settingsRepository: _FakeSettingsRepository(),
      debounceDuration: Duration.zero,
    );

    viewModel.updateQuery('测试');
    await Future<void>.delayed(Duration.zero);
    repository.complete('测试', List<String>.generate(10, (index) => '结果$index'));
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.state.suggestions, hasLength(8));
    expect(viewModel.state.suggestions.last, '结果7');
    viewModel.dispose();
  });

  test('建议请求期间销毁后完成结果不会通知已销毁 ViewModel', () async {
    final repository = _FakeSearchRepository();
    final viewModel = ShellViewModel(
      searchRepository: repository,
      settingsRepository: _FakeSettingsRepository(),
      debounceDuration: Duration.zero,
    );

    viewModel.updateQuery('退出页面');
    await Future<void>.delayed(Duration.zero);
    viewModel.dispose();
    repository.complete('退出页面', <String>['晚到结果']);
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.state.suggestions, isEmpty);
  });
}

final class _FakeSearchRepository implements SearchRepository {
  final List<String> queries = <String>[];
  final Map<String, Completer<Result<List<String>>>> _requests =
      <String, Completer<Result<List<String>>>>{};

  void complete(String query, List<String> values) {
    _requests[query]!.complete(Success<List<String>>(values));
  }

  @override
  Future<Result<List<String>>> getSuggestions(
    String query, {
    required bool localSearchEnabled,
  }) {
    queries.add(query);
    final completer = Completer<Result<List<String>>>();
    _requests[query] = completer;
    return completer.future;
  }

  @override
  void clearCache() {}

  @override
  Future<Result<List<SearchResult>>> getLocalDetail(
    String source,
    String id,
  ) async => const Success<List<SearchResult>>(<SearchResult>[]);

  @override
  Future<Result<List<String>>> searchRecommendations(String query) async =>
      const Success<List<String>>(<String>[]);

  @override
  Future<Result<List<SearchResult>>> searchLocal(String query) async =>
      const Success<List<SearchResult>>(<SearchResult>[]);
}

final class _FakeSettingsRepository implements SettingsRepository {
  @override
  Future<Result<AppSettings>> load() async =>
      const Success<AppSettings>(AppSettings());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
