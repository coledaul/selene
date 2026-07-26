import '../../domain/models/subscription.dart';
import '../../utils/result.dart';
import '../services/subscription_api_service.dart';
import '../services/subscription_local_service.dart';

abstract interface class SubscriptionRepository {
  Future<String> loadUrl();
  Future<Result<SubscriptionCandidate>> prepare(String url);
  Future<Result<void>> save(SubscriptionCandidate candidate);
  Future<Result<void>> refresh();
  void dispose();
}

class DefaultSubscriptionRepository implements SubscriptionRepository {
  DefaultSubscriptionRepository({
    required SubscriptionApiService apiService,
    required SubscriptionLocalService localService,
    required void Function() invalidateCaches,
  }) : _apiService = apiService,
       _localService = localService,
       _invalidateCaches = invalidateCaches;

  final SubscriptionApiService _apiService;
  final SubscriptionLocalService _localService;
  final void Function() _invalidateCaches;
  bool _disposed = false;

  @override
  Future<String> loadUrl() async => await _localService.loadUrl() ?? '';

  @override
  Future<Result<SubscriptionCandidate>> prepare(String url) async {
    final normalized = url.trim();
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.validation,
          message: '请输入有效的 HTTP(S) 订阅地址',
        ),
      );
    }

    final payloadResult = await _apiService.fetch(normalized);
    final oldUrl = await _localService.loadUrl();
    final replacesExistingData =
        oldUrl != null && oldUrl.isNotEmpty && oldUrl != normalized;
    return switch (payloadResult) {
      Success<SubscriptionPayload>(:final value) => Success(
        SubscriptionCandidate(
          url: normalized,
          searchSources: value.searchSources,
          liveSources: value.liveSources,
          replacesExistingData: replacesExistingData,
        ),
      ),
      FailureResult<SubscriptionPayload>(:final failure) => FailureResult(
        failure,
      ),
    };
  }

  @override
  Future<Result<void>> save(SubscriptionCandidate candidate) async {
    try {
      await _localService.save(
        candidate,
        clearOldData: candidate.replacesExistingData,
      );
      _invalidateCaches();
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.storage,
          message: '无法保存本地订阅',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<void>> refresh() async {
    final url = await loadUrl();
    if (url.isEmpty) {
      return const Success<void>(null);
    }
    final prepared = await prepare(url);
    return switch (prepared) {
      Success<SubscriptionCandidate>(:final value) => save(value),
      FailureResult<SubscriptionCandidate>(:final failure) => FailureResult(
        failure,
      ),
    };
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _apiService.dispose();
  }
}
