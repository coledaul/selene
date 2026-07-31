import '../../../domain/models/app_release_asset.dart';
import '../../../domain/models/app_update_transfer.dart';
import '../../services/update/update_download_service.dart';
import '../../services/update/update_source_service.dart';

/// 单次更新下载的不可变输入和有序线路游标。
///
/// 它只负责生成确定性任务请求，不执行 I/O，也不持有 UI 状态。
final class UpdateDownloadPlan {
  UpdateDownloadPlan({
    required this.version,
    required this.asset,
    required this.requestedSource,
    required this.priority,
    required List<UpdateSourceCandidate> candidates,
  }) : _candidates = List<UpdateSourceCandidate>.unmodifiable(candidates);

  final String version;
  final AppReleaseAsset asset;
  final UpdateDownloadSource requestedSource;
  final int priority;
  final List<UpdateSourceCandidate> _candidates;
  int _index = 0;

  bool get hasCandidate => _index < _candidates.length;

  UpdateDownloadRequest get currentRequest {
    final candidate = _candidates[_index];
    return UpdateDownloadRequest(
      taskId: _taskId(version, asset.architecture.name, candidate.source),
      version: version,
      asset: asset,
      source: candidate.source,
      uri: candidate.uri,
      // 自动模式不在首选线路重复等待；只有最终兜底或手动线路由插件重试。
      retries:
          requestedSource == UpdateDownloadSource.automatic &&
              _index + 1 < _candidates.length
          ? 0
          : 2,
      priority: priority,
    );
  }

  bool moveNext() {
    if (_index + 1 >= _candidates.length) return false;
    _index++;
    return true;
  }

  static String _taskId(
    String version,
    String architecture,
    UpdateDownloadSource source,
  ) => 'selene-update-$version-$architecture-${source.name}';
}
