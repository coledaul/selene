import '../../domain/models/local_media_lease.dart';
import '../../utils/result.dart';
import '../ports/local_media_port.dart';
import '../services/local_media_server_service.dart';

final class DefaultLocalMediaRepository implements LocalMediaRepository {
  const DefaultLocalMediaRepository({required LocalMediaServerService service})
    : _service = service;

  final LocalMediaServerService _service;

  @override
  Future<Result<LocalMediaLease>> publishFile({
    required String filePath,
    required String targetHost,
  }) => _service.publishFile(filePath: filePath, targetHost: targetHost);

  @override
  Future<Result<void>> release(LocalMediaLease lease) =>
      _service.release(lease);

  @override
  Future<void> dispose() => _service.dispose();
}
