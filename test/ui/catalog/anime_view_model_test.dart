import 'package:flutter_test/flutter_test.dart';
import 'package:selene/data/repositories/anime_repository.dart';
import 'package:selene/data/services/api_service.dart';
import 'package:selene/data/services/content_data_service.dart';
import 'package:selene/domain/models/anime_catalog.dart';
import 'package:selene/domain/models/bangumi.dart';
import 'package:selene/domain/models/douban_movie.dart';
import 'package:selene/ui/catalog/view_models/anime_view_model.dart';
import 'package:selene/utils/result.dart';

void main() {
  test('AnimeRepository 在星期日仍向 Bangumi 传递 7', () async {
    final service = _FakeContentDataService();
    final repository = DefaultAnimeRepository(
      service: service,
      clock: () => DateTime(2026, 7, 26),
    );

    final result = await repository.getTodayCalendar();

    expect(result, isA<Success<List<BangumiItem>>>());
    expect(service.weekday, DateTime.sunday);
  });

  group('AnimeViewModel', () {
    test('默认按当天星期加载 Bangumi 日历且不启用分页', () async {
      final repository = _FakeAnimeRepository();
      final viewModel = AnimeViewModel(repository: repository);

      await viewModel.initialize();

      expect(repository.calendarWeekday, DateTime.now().weekday);
      expect(viewModel.state.calendarItems, hasLength(1));
      expect(viewModel.state.hasMore, isFalse);
      viewModel.dispose();
    });

    test('番剧和剧场版复用分页状态机但生成不同结构化查询', () async {
      final repository = _FakeAnimeRepository();
      final viewModel = AnimeViewModel(repository: repository);
      await viewModel.initialize();

      await viewModel.selectCategory('番剧');
      await viewModel.selectAnimeRegion('japanese');
      expect(repository.queries.last.type, AnimeCatalogType.series);
      expect(repository.queries.last.region, 'japanese');

      await viewModel.selectCategory('剧场版');
      await viewModel.selectMovieType('stop_motion');
      expect(repository.queries.last.type, AnimeCatalogType.movie);
      expect(repository.queries.last.genre, 'stop_motion');
      viewModel.dispose();
    });
  });
}

final class _FakeContentDataService implements ContentDataService {
  int? weekday;

  @override
  Future<ApiResponse<List<BangumiItem>>> getCalendar(int weekday) async {
    this.weekday = weekday;
    return ApiResponse<List<BangumiItem>>.success(<BangumiItem>[]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeAnimeRepository implements AnimeRepository {
  int? calendarWeekday;
  final List<AnimeCatalogQuery> queries = <AnimeCatalogQuery>[];

  @override
  Future<Result<List<BangumiItem>>> getTodayCalendar() =>
      getCalendar(DateTime.now().weekday);

  @override
  Future<Result<List<BangumiItem>>> getCalendar(int weekday) async {
    calendarWeekday = weekday;
    return Success<List<BangumiItem>>(<BangumiItem>[_bangumi()]);
  }

  @override
  Future<Result<List<DoubanMovie>>> getCatalog(AnimeCatalogQuery query) async {
    queries.add(query);
    return Success<List<DoubanMovie>>(<DoubanMovie>[
      DoubanMovie(
        id: '${queries.length}',
        title: '动漫',
        poster: '',
        year: '2026',
      ),
    ]);
  }
}

BangumiItem _bangumi() => BangumiItem.fromJson(<String, dynamic>{
  'id': 1,
  'name': '测试番剧',
  'name_cn': '测试番剧',
  'summary': '',
  'air_date': '2026-01-01',
  'air_weekday': 1,
  'images': <String, dynamic>{
    'large': 'https://example.com/cover.jpg',
    'common': 'https://example.com/cover.jpg',
    'medium': 'https://example.com/cover.jpg',
    'small': 'https://example.com/cover.jpg',
    'grid': 'https://example.com/cover.jpg',
  },
  'rating': <String, dynamic>{
    'score': 8.0,
    'total': 1,
    'count': <String, dynamic>{},
  },
  'rank': 1,
  'collection': <String, dynamic>{},
});
