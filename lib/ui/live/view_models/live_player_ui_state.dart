import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/models/epg_program.dart';
import '../../../domain/models/live_channel.dart';
import '../../../domain/models/live_source.dart';

part 'live_player_ui_state.freezed.dart';

@freezed
abstract class LivePlayerUiState with _$LivePlayerUiState {
  const LivePlayerUiState._();

  const factory LivePlayerUiState({
    required LiveChannel currentChannel,
    required LiveSource currentSource,
    @Default(<LiveChannel>[]) List<LiveChannel> channels,
    @Default(<LiveSource>[]) List<LiveSource> sources,
    List<EpgProgram>? programs,
    @Default(false) bool loadingEpg,
    @Default('全部') String selectedGroup,
    String? error,
  }) = _LivePlayerUiState;

  List<LiveChannel> get filteredChannels => selectedGroup == '全部'
      ? channels
      : channels
            .where((channel) => channel.group == selectedGroup)
            .toList(growable: false);
}
