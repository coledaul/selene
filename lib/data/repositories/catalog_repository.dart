import '../../domain/models/catalog.dart';
import '../../domain/models/douban_movie.dart';
import '../services/content_data_service.dart';
import '../../utils/result.dart';

abstract interface class CatalogRepository {
  Future<Result<List<DoubanMovie>>> fetch(CatalogQuery query);
  Future<Result<List<DoubanMovie>>> fetchHot(CatalogType type);
}

final class DefaultCatalogRepository implements CatalogRepository {
  DefaultCatalogRepository({ContentDataService? service})
    : _service = service ?? const DefaultContentDataService();

  final ContentDataService _service;

  @override
  Future<Result<List<DoubanMovie>>> fetchHot(CatalogType type) async {
    try {
      final response = switch (type) {
        CatalogType.movie => await _service.getHotMovies(),
        CatalogType.tv => await _service.getHotTvShows(),
        CatalogType.show => await _service.getHotShows(),
      };
      final data = response.data;
      if (response.success && data != null) {
        return Success(List<DoubanMovie>.unmodifiable(data));
      }
      return FailureResult(
        AppFailure(
          kind: FailureKind.network,
          message: response.message ?? '加载热门内容失败',
        ),
      );
    } catch (error, stackTrace) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.network,
          message: '加载热门内容失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<List<DoubanMovie>>> fetch(CatalogQuery query) async {
    try {
      final response = query.advanced
          ? await _service.getRecommendations(
              ContentRecommendationQuery(
                kind: query.definition.apiKind,
                category: _label(query.definition.typeOptions, query.type),
                format: query.definition.advancedFormat ?? 'all',
                region: _label(query.definition.regionOptions, query.region),
                year: _label(query.definition.yearOptions, query.year),
                platform: query.definition.supportsPlatform
                    ? _label(query.definition.platformOptions, query.platform)
                    : 'all',
                sort: query.sort,
                pageLimit: query.pageLimit,
                page: query.page,
              ),
            )
          : await _service.getCategoryData(
              kind: query.definition.apiKind,
              category: query.definition.type == CatalogType.show
                  ? 'show'
                  : query.category,
              type: query.secondary,
              pageLimit: query.pageLimit,
              page: query.page,
            );
      final data = response.data;
      if (response.success && data != null) {
        return Success<List<DoubanMovie>>(List<DoubanMovie>.unmodifiable(data));
      }
      return FailureResult(
        AppFailure(
          kind: FailureKind.network,
          message: response.message ?? '加载内容失败',
        ),
      );
    } catch (error, stackTrace) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.network,
          message: '加载内容失败',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  String _label(List<CatalogFilterOption> options, String value) {
    if (value == 'all') return 'all';
    return options
        .firstWhere(
          (option) => option.value == value,
          orElse: () => options.first,
        )
        .label;
  }
}
