import '../../domain/models/anime_catalog.dart';
import '../../domain/models/bangumi.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/douban_movie.dart';
import '../services/content_data_service.dart';
import '../../utils/result.dart';

abstract interface class AnimeRepository {
  Future<Result<List<BangumiItem>>> getTodayCalendar();
  Future<Result<List<BangumiItem>>> getCalendar(int weekday);
  Future<Result<List<DoubanMovie>>> getCatalog(AnimeCatalogQuery query);
}

final class DefaultAnimeRepository implements AnimeRepository {
  DefaultAnimeRepository({
    ContentDataService? service,
    DateTime Function()? clock,
  }) : _service = service ?? const DefaultContentDataService(),
       _clock = clock ?? DateTime.now;

  final ContentDataService _service;
  final DateTime Function() _clock;

  @override
  Future<Result<List<BangumiItem>>> getTodayCalendar() async {
    return getCalendar(_clock().weekday);
  }

  @override
  Future<Result<List<BangumiItem>>> getCalendar(int weekday) async {
    try {
      if (weekday < DateTime.monday || weekday > DateTime.sunday) {
        return _failure('星期参数必须在 1 到 7 之间');
      }
      final response = await _service.getCalendar(weekday);
      final data = response.data;
      if (response.success && data != null) {
        return Success(
          List<BangumiItem>.unmodifiable(
            data.where((item) => item.images.bestImageUrl.isNotEmpty),
          ),
        );
      }
      return _failure(response.message ?? '加载 Bangumi 日历失败');
    } catch (error, stackTrace) {
      return _failure('加载 Bangumi 日历失败', error, stackTrace);
    }
  }

  @override
  Future<Result<List<DoubanMovie>>> getCatalog(AnimeCatalogQuery query) async {
    try {
      final series = query.type == AnimeCatalogType.series;
      final definition = AnimeCatalogDefinition.forType(query.type);
      final response = await _service.getRecommendations(
        ContentRecommendationQuery(
          kind: series ? 'tv' : 'movie',
          category: '动画',
          label: _label(definition.typeOptions, query.genre),
          format: series ? '电视剧' : '',
          region: _label(definition.regionOptions, query.region),
          year: _label(definition.yearOptions, query.year),
          platform: series
              ? _label(definition.platformOptions, query.platform)
              : 'all',
          sort: query.sort,
          pageLimit: query.pageLimit,
          page: query.page,
        ),
      );
      final data = response.data;
      if (response.success && data != null) {
        return Success(List<DoubanMovie>.unmodifiable(data));
      }
      return _failure(response.message ?? '加载动漫内容失败');
    } catch (error, stackTrace) {
      return _failure('加载动漫内容失败', error, stackTrace);
    }
  }

  FailureResult<List<T>> _failure<T>(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    return FailureResult<List<T>>(
      AppFailure(
        kind: FailureKind.network,
        message: message,
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  String _label(List<CatalogFilterOption> options, String value) {
    if (value == 'all') return 'all';
    return options
        .firstWhere(
          (option) => option.value == value,
          orElse: () => CatalogFilterOption(value, value),
        )
        .label;
  }
}
