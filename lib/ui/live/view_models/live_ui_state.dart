import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/models/live_channel.dart';
import '../../../domain/models/live_source.dart';

part 'live_ui_state.freezed.dart';

@freezed
abstract class LiveUiState with _$LiveUiState {
  const LiveUiState._();

  const factory LiveUiState({
    @Default(<LiveSource>[]) List<LiveSource> sources,
    @Default(<LiveChannelGroup>[]) List<LiveChannelGroup> groups,
    LiveSource? currentSource,
    @Default('全部') String selectedGroup,
    @Default(true) bool loading,
    @Default(false) bool refreshing,
    @Default(true) bool initialLoad,
    String? error,
    String? notice,
  }) = _LiveUiState;

  List<LiveChannel> get filteredChannels {
    if (selectedGroup == '全部') {
      return groups.expand((group) => group.channels).toList(growable: false);
    }
    for (final group in groups) {
      if (group.name == selectedGroup) {
        return group.channels;
      }
    }
    return const <LiveChannel>[];
  }
}
