// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SettingsUiState {
  bool get loading;
  bool get localMode;
  String get username;
  String get role;
  AppSettings get settings;
  AppVersionInfo? get availableUpdate;

  /// Create a copy of SettingsUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SettingsUiStateCopyWith<SettingsUiState> get copyWith =>
      _$SettingsUiStateCopyWithImpl<SettingsUiState>(
        this as SettingsUiState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SettingsUiState &&
            (identical(other.loading, loading) || other.loading == loading) &&
            (identical(other.localMode, localMode) ||
                other.localMode == localMode) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
            (identical(other.availableUpdate, availableUpdate) ||
                other.availableUpdate == availableUpdate));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    loading,
    localMode,
    username,
    role,
    settings,
    availableUpdate,
  );

  @override
  String toString() {
    return 'SettingsUiState(loading: $loading, localMode: $localMode, username: $username, role: $role, settings: $settings, availableUpdate: $availableUpdate)';
  }
}

/// @nodoc
abstract mixin class $SettingsUiStateCopyWith<$Res> {
  factory $SettingsUiStateCopyWith(
    SettingsUiState value,
    $Res Function(SettingsUiState) _then,
  ) = _$SettingsUiStateCopyWithImpl;
  @useResult
  $Res call({
    bool loading,
    bool localMode,
    String username,
    String role,
    AppSettings settings,
    AppVersionInfo? availableUpdate,
  });

  $AppSettingsCopyWith<$Res> get settings;
  $AppVersionInfoCopyWith<$Res>? get availableUpdate;
}

/// @nodoc
class _$SettingsUiStateCopyWithImpl<$Res>
    implements $SettingsUiStateCopyWith<$Res> {
  _$SettingsUiStateCopyWithImpl(this._self, this._then);

  final SettingsUiState _self;
  final $Res Function(SettingsUiState) _then;

  /// Create a copy of SettingsUiState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? loading = null,
    Object? localMode = null,
    Object? username = null,
    Object? role = null,
    Object? settings = null,
    Object? availableUpdate = freezed,
  }) {
    return _then(
      _self.copyWith(
        loading: null == loading
            ? _self.loading
            : loading // ignore: cast_nullable_to_non_nullable
                  as bool,
        localMode: null == localMode
            ? _self.localMode
            : localMode // ignore: cast_nullable_to_non_nullable
                  as bool,
        username: null == username
            ? _self.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
        role: null == role
            ? _self.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String,
        settings: null == settings
            ? _self.settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as AppSettings,
        availableUpdate: freezed == availableUpdate
            ? _self.availableUpdate
            : availableUpdate // ignore: cast_nullable_to_non_nullable
                  as AppVersionInfo?,
      ),
    );
  }

  /// Create a copy of SettingsUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AppSettingsCopyWith<$Res> get settings {
    return $AppSettingsCopyWith<$Res>(_self.settings, (value) {
      return _then(_self.copyWith(settings: value));
    });
  }

  /// Create a copy of SettingsUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AppVersionInfoCopyWith<$Res>? get availableUpdate {
    if (_self.availableUpdate == null) {
      return null;
    }

    return $AppVersionInfoCopyWith<$Res>(_self.availableUpdate!, (value) {
      return _then(_self.copyWith(availableUpdate: value));
    });
  }
}

/// Adds pattern-matching-related methods to [SettingsUiState].
extension SettingsUiStatePatterns on SettingsUiState {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_SettingsUiState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SettingsUiState() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_SettingsUiState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SettingsUiState():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_SettingsUiState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SettingsUiState() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      bool loading,
      bool localMode,
      String username,
      String role,
      AppSettings settings,
      AppVersionInfo? availableUpdate,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SettingsUiState() when $default != null:
        return $default(
          _that.loading,
          _that.localMode,
          _that.username,
          _that.role,
          _that.settings,
          _that.availableUpdate,
        );
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      bool loading,
      bool localMode,
      String username,
      String role,
      AppSettings settings,
      AppVersionInfo? availableUpdate,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SettingsUiState():
        return $default(
          _that.loading,
          _that.localMode,
          _that.username,
          _that.role,
          _that.settings,
          _that.availableUpdate,
        );
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      bool loading,
      bool localMode,
      String username,
      String role,
      AppSettings settings,
      AppVersionInfo? availableUpdate,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SettingsUiState() when $default != null:
        return $default(
          _that.loading,
          _that.localMode,
          _that.username,
          _that.role,
          _that.settings,
          _that.availableUpdate,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _SettingsUiState implements SettingsUiState {
  const _SettingsUiState({
    this.loading = false,
    this.localMode = false,
    this.username = '',
    this.role = 'user',
    this.settings = const AppSettings(),
    this.availableUpdate,
  });

  @override
  @JsonKey()
  final bool loading;
  @override
  @JsonKey()
  final bool localMode;
  @override
  @JsonKey()
  final String username;
  @override
  @JsonKey()
  final String role;
  @override
  @JsonKey()
  final AppSettings settings;
  @override
  final AppVersionInfo? availableUpdate;

  /// Create a copy of SettingsUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SettingsUiStateCopyWith<_SettingsUiState> get copyWith =>
      __$SettingsUiStateCopyWithImpl<_SettingsUiState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SettingsUiState &&
            (identical(other.loading, loading) || other.loading == loading) &&
            (identical(other.localMode, localMode) ||
                other.localMode == localMode) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
            (identical(other.availableUpdate, availableUpdate) ||
                other.availableUpdate == availableUpdate));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    loading,
    localMode,
    username,
    role,
    settings,
    availableUpdate,
  );

  @override
  String toString() {
    return 'SettingsUiState(loading: $loading, localMode: $localMode, username: $username, role: $role, settings: $settings, availableUpdate: $availableUpdate)';
  }
}

/// @nodoc
abstract mixin class _$SettingsUiStateCopyWith<$Res>
    implements $SettingsUiStateCopyWith<$Res> {
  factory _$SettingsUiStateCopyWith(
    _SettingsUiState value,
    $Res Function(_SettingsUiState) _then,
  ) = __$SettingsUiStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    bool loading,
    bool localMode,
    String username,
    String role,
    AppSettings settings,
    AppVersionInfo? availableUpdate,
  });

  @override
  $AppSettingsCopyWith<$Res> get settings;
  @override
  $AppVersionInfoCopyWith<$Res>? get availableUpdate;
}

/// @nodoc
class __$SettingsUiStateCopyWithImpl<$Res>
    implements _$SettingsUiStateCopyWith<$Res> {
  __$SettingsUiStateCopyWithImpl(this._self, this._then);

  final _SettingsUiState _self;
  final $Res Function(_SettingsUiState) _then;

  /// Create a copy of SettingsUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? loading = null,
    Object? localMode = null,
    Object? username = null,
    Object? role = null,
    Object? settings = null,
    Object? availableUpdate = freezed,
  }) {
    return _then(
      _SettingsUiState(
        loading: null == loading
            ? _self.loading
            : loading // ignore: cast_nullable_to_non_nullable
                  as bool,
        localMode: null == localMode
            ? _self.localMode
            : localMode // ignore: cast_nullable_to_non_nullable
                  as bool,
        username: null == username
            ? _self.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
        role: null == role
            ? _self.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String,
        settings: null == settings
            ? _self.settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as AppSettings,
        availableUpdate: freezed == availableUpdate
            ? _self.availableUpdate
            : availableUpdate // ignore: cast_nullable_to_non_nullable
                  as AppVersionInfo?,
      ),
    );
  }

  /// Create a copy of SettingsUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AppSettingsCopyWith<$Res> get settings {
    return $AppSettingsCopyWith<$Res>(_self.settings, (value) {
      return _then(_self.copyWith(settings: value));
    });
  }

  /// Create a copy of SettingsUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AppVersionInfoCopyWith<$Res>? get availableUpdate {
    if (_self.availableUpdate == null) {
      return null;
    }

    return $AppVersionInfoCopyWith<$Res>(_self.availableUpdate!, (value) {
      return _then(_self.copyWith(availableUpdate: value));
    });
  }
}
