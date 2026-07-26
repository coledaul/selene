import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/models/app_settings.dart';
import '../../../domain/models/app_version.dart';

part 'settings_ui_state.freezed.dart';

@freezed
abstract class SettingsUiState with _$SettingsUiState {
  const factory SettingsUiState({
    @Default(false) bool loading,
    @Default(false) bool localMode,
    @Default('') String username,
    @Default('user') String role,
    @Default(AppSettings()) AppSettings settings,
    AppVersionInfo? availableUpdate,
  }) = _SettingsUiState;
}
