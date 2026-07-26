import '../../domain/models/bangumi.dart';
import '../../domain/models/douban_movie.dart';
import '../services/content_data_service.dart';
import '../../utils/result.dart';

abstract interface class MetadataRepository {
  Future<Result<DoubanMovieDetails?>> getDoubanDetails(String id);
  Future<Result<BangumiDetails?>> getBangumiDetails(String id);
}

final class DefaultMetadataRepository implements MetadataRepository {
  DefaultMetadataRepository({ContentDataService? service})
    : _service = service ?? const DefaultContentDataService();

  final ContentDataService _service;

  @override
  Future<Result<DoubanMovieDetails?>> getDoubanDetails(String id) async {
    try {
      final response = await _service.getDoubanDetails(id);
      if (response.success) return Success(response.data);
      return _failure(response.message ?? '获取豆瓣详情失败');
    } catch (error, stackTrace) {
      return _failure('获取豆瓣详情失败', error, stackTrace);
    }
  }

  @override
  Future<Result<BangumiDetails?>> getBangumiDetails(String id) async {
    try {
      final response = await _service.getBangumiDetails(id);
      if (response.success) return Success(response.data);
      return _failure(response.message ?? '获取 Bangumi 详情失败');
    } catch (error, stackTrace) {
      return _failure('获取 Bangumi 详情失败', error, stackTrace);
    }
  }

  FailureResult<T> _failure<T>(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) => FailureResult(
    AppFailure(
      kind: FailureKind.network,
      message: message,
      cause: error,
      stackTrace: stackTrace,
    ),
  );
}
