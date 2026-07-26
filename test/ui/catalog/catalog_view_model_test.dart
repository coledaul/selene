import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/catalog_repository.dart';
import 'package:selene/domain/models/catalog.dart';
import 'package:selene/domain/models/douban_movie.dart';
import 'package:selene/ui/catalog/view_models/catalog_view_model.dart';
import 'package:selene/utils/result.dart';

void main() {
  group('CatalogViewModel', () {
    test('分页结果由单一 ViewModel 追加且空页结束分页', () async {
      final repository = _FakeCatalogRepository(<List<DoubanMovie>>[
        <DoubanMovie>[_movie('1')],
        <DoubanMovie>[_movie('2')],
        <DoubanMovie>[],
      ]);
      final viewModel = CatalogViewModel(
        repository: repository,
        definition: CatalogDefinition.movie,
      );

      await viewModel.initialize();
      await viewModel.loadMore();
      await viewModel.loadMore();

      expect(viewModel.state.items.map((item) => item.id), <String>['1', '2']);
      expect(viewModel.state.page, 3);
      expect(viewModel.state.hasMore, isFalse);
      viewModel.dispose();
    });

    test('切换高级筛选会重置分页并传递结构化查询', () async {
      final repository = _FakeCatalogRepository(<List<DoubanMovie>>[
        <DoubanMovie>[_movie('1')],
        <DoubanMovie>[_movie('2')],
        <DoubanMovie>[_movie('3')],
      ]);
      final viewModel = CatalogViewModel(
        repository: repository,
        definition: CatalogDefinition.tv,
      );
      await viewModel.initialize();

      await viewModel.selectCategory('全部');
      await viewModel.selectRegion('korean');

      final query = repository.queries.last;
      expect(query.advanced, isTrue);
      expect(query.region, 'korean');
      expect(query.page, 0);
      expect(viewModel.state.items.single.id, '3');
      viewModel.dispose();
    });

    test('首屏失败保留错误，合法空页与失败状态可区分', () async {
      final repository = _FakeCatalogRepository(<List<DoubanMovie>>[])
        ..failure = const AppFailure(
          kind: FailureKind.network,
          message: '豆瓣请求失败',
        );
      final viewModel = CatalogViewModel(
        repository: repository,
        definition: CatalogDefinition.show,
      );

      final result = await viewModel.initialize();

      expect(result, isA<FailureResult<void>>());
      expect(viewModel.state.error, '豆瓣请求失败');
      expect(viewModel.state.loading, isFalse);
      viewModel.dispose();
    });

    test('请求期间销毁后完成结果不会写入已销毁 ViewModel', () async {
      final repository = _ControlledCatalogRepository();
      final viewModel = CatalogViewModel(
        repository: repository,
        definition: CatalogDefinition.movie,
      );

      final loading = viewModel.initialize();
      viewModel.dispose();
      repository.complete(<DoubanMovie>[_movie('late')]);

      await expectLater(loading, completes);
      expect(viewModel.state.items, isEmpty);
    });
  });
}

final class _ControlledCatalogRepository implements CatalogRepository {
  final _request = Completer<Result<List<DoubanMovie>>>();

  void complete(List<DoubanMovie> values) {
    _request.complete(Success<List<DoubanMovie>>(values));
  }

  @override
  Future<Result<List<DoubanMovie>>> fetch(CatalogQuery query) =>
      _request.future;

  @override
  Future<Result<List<DoubanMovie>>> fetchHot(CatalogType type) async =>
      const Success(<DoubanMovie>[]);
}

final class _FakeCatalogRepository implements CatalogRepository {
  _FakeCatalogRepository(this.pages);

  final List<List<DoubanMovie>> pages;
  final List<CatalogQuery> queries = <CatalogQuery>[];
  AppFailure? failure;

  @override
  Future<Result<List<DoubanMovie>>> fetchHot(CatalogType type) async =>
      const Success(<DoubanMovie>[]);

  @override
  Future<Result<List<DoubanMovie>>> fetch(CatalogQuery query) async {
    queries.add(query);
    final currentFailure = failure;
    if (currentFailure != null) {
      return FailureResult<List<DoubanMovie>>(currentFailure);
    }
    final index = queries.length - 1;
    return Success<List<DoubanMovie>>(
      index < pages.length ? pages[index] : const <DoubanMovie>[],
    );
  }
}

DoubanMovie _movie(String id) =>
    DoubanMovie(id: id, title: '标题$id', poster: '', year: '2026');
