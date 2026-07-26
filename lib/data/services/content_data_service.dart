import '../../domain/models/bangumi.dart';
import '../../domain/models/douban_movie.dart';
import 'api_service.dart';
import 'bangumi_service.dart';
import 'douban_service.dart';

final class ContentRecommendationQuery {
  const ContentRecommendationQuery({
    required this.kind,
    this.category = 'all',
    this.format = 'all',
    this.region = 'all',
    this.year = 'all',
    this.platform = 'all',
    this.sort = 'T',
    this.label = 'all',
    this.pageLimit = 20,
    this.page = 0,
  });

  final String kind;
  final String category;
  final String format;
  final String region;
  final String year;
  final String platform;
  final String sort;
  final String label;
  final int pageLimit;
  final int page;
}

/// 豆瓣与 Bangumi 外部数据访问端口。
abstract interface class ContentDataService {
  Future<ApiResponse<List<DoubanMovie>>> getHotMovies();
  Future<ApiResponse<List<DoubanMovie>>> getHotTvShows();
  Future<ApiResponse<List<DoubanMovie>>> getHotShows();
  Future<ApiResponse<List<DoubanMovie>>> getCategoryData({
    required String kind,
    required String category,
    required String type,
    required int pageLimit,
    required int page,
  });
  Future<ApiResponse<List<DoubanMovie>>> getRecommendations(
    ContentRecommendationQuery query,
  );
  Future<ApiResponse<DoubanMovieDetails>> getDoubanDetails(String id);
  Future<ApiResponse<List<BangumiItem>>> getCalendar(int weekday);
  Future<ApiResponse<BangumiDetails>> getBangumiDetails(String id);
}

final class DefaultContentDataService implements ContentDataService {
  const DefaultContentDataService();

  @override
  Future<ApiResponse<List<DoubanMovie>>> getHotMovies() =>
      DoubanService.getHotMovies();

  @override
  Future<ApiResponse<List<DoubanMovie>>> getHotTvShows() =>
      DoubanService.getHotTvShows();

  @override
  Future<ApiResponse<List<DoubanMovie>>> getHotShows() =>
      DoubanService.getHotShows();

  @override
  Future<ApiResponse<List<DoubanMovie>>> getCategoryData({
    required String kind,
    required String category,
    required String type,
    required int pageLimit,
    required int page,
  }) => DoubanService.getCategoryData(
    kind: kind,
    category: category,
    type: type,
    pageLimit: pageLimit,
    page: page,
  );

  @override
  Future<ApiResponse<List<DoubanMovie>>> getRecommendations(
    ContentRecommendationQuery query,
  ) => DoubanService.fetchDoubanRecommends(
    DoubanRecommendsParams(
      kind: query.kind,
      category: query.category,
      format: query.format,
      region: query.region,
      year: query.year,
      platform: query.platform,
      sort: query.sort,
      label: query.label,
      pageLimit: query.pageLimit,
      page: query.page,
    ),
  );

  @override
  Future<ApiResponse<DoubanMovieDetails>> getDoubanDetails(String id) =>
      DoubanService.getDoubanDetails(doubanId: id);

  @override
  Future<ApiResponse<List<BangumiItem>>> getCalendar(int weekday) =>
      BangumiService.getCalendarByWeekday(weekday);

  @override
  Future<ApiResponse<BangumiDetails>> getBangumiDetails(String id) =>
      BangumiService.getBangumiDetails(bangumiId: id);
}
