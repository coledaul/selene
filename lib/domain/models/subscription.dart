import 'package:freezed_annotation/freezed_annotation.dart';

import 'live_source.dart';
import 'search_resource.dart';

part 'subscription.freezed.dart';

@freezed
abstract class SubscriptionCandidate with _$SubscriptionCandidate {
  const factory SubscriptionCandidate({
    required String url,
    required List<SearchResource> searchSources,
    required List<LiveSource> liveSources,
    required bool replacesExistingData,
  }) = _SubscriptionCandidate;
}
