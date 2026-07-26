import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/subscription.dart';

abstract interface class SubscriptionLocalService {
  Future<String?> loadUrl();
  Future<void> save(
    SubscriptionCandidate candidate, {
    required bool clearOldData,
  });
}

class SharedPreferencesSubscriptionLocalService
    implements SubscriptionLocalService {
  SharedPreferencesSubscriptionLocalService({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  static const _subscriptionUrlKey = 'local_mode_subscription_url';
  static const _searchSourcesKey = 'local_mode_search_sources';
  static const _liveSourcesKey = 'local_mode_live_sources';
  static const _localDataKeys = <String>[
    _subscriptionUrlKey,
    _searchSourcesKey,
    _liveSourcesKey,
    'local_mode_play_records',
    'local_mode_favorites',
    'local_mode_search_history',
  ];

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> loadUrl() => _preferences.getString(_subscriptionUrlKey);

  @override
  Future<void> save(
    SubscriptionCandidate candidate, {
    required bool clearOldData,
  }) async {
    if (clearOldData) {
      await Future.wait(_localDataKeys.map(_preferences.remove));
    }
    await Future.wait<void>([
      _preferences.setString(_subscriptionUrlKey, candidate.url),
      _preferences.setString(
        _searchSourcesKey,
        jsonEncode(
          candidate.searchSources.map((item) => item.toJson()).toList(),
        ),
      ),
      _preferences.setString(
        _liveSourcesKey,
        jsonEncode(candidate.liveSources.map((item) => item.toJson()).toList()),
      ),
    ]);
  }
}
