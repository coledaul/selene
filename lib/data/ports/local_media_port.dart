import '../../domain/models/local_media_lease.dart';
import '../../utils/result.dart';

abstract interface class LocalMediaRepository {
  Future<Result<LocalMediaLease>> publishFile({
    required String filePath,
    required String targetHost,
  });

  Future<Result<void>> release(LocalMediaLease lease);

  Future<void> dispose();
}
