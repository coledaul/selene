// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_player_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LivePlayerUiState {
  LiveChannel get currentChannel;
  LiveSource get currentSource;
  List<LiveChannel> get channels;
  List<LiveSource> get sources;
  List<EpgProgram>? get programs;
  bool get loadingEpg;
  String get selectedGroup;
  String? get error;

  /// Create a copy of LivePlayerUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LivePlayerUiStateCopyWith<LivePlayerUiState> get copyWith =>
      _$LivePlayerUiStateCopyWithImpl<LivePlayerUiState>(
        this as LivePlayerUiState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LivePlayerUiState &&
            (identical(other.currentChannel, currentChannel) ||
                other.currentChannel == currentChannel) &&
            (identical(other.currentSource, currentSource) ||
                other.currentSource == currentSource) &&
            const DeepCollectionEquality().equals(other.channels, channels) &&
            const DeepCollectionEquality().equals(other.sources, sources) &&
            const DeepCollectionEquality().equals(other.programs, programs) &&
            (identical(other.loadingEpg, loadingEpg) ||
                other.loadingEpg == loadingEpg) &&
            (identical(other.selectedGroup, selectedGroup) ||
                other.selectedGroup == selectedGroup) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    currentChannel,
    currentSource,
    const DeepCollectionEquality().hash(channels),
    const DeepCollectionEquality().hash(sources),
    const DeepCollectionEquality().hash(programs),
    loadingEpg,
    selectedGroup,
    error,
  );

  @override
  String toString() {
    return 'LivePlayerUiState(currentChannel: $currentChannel, currentSource: $currentSource, channels: $channels, sources: $sources, programs: $programs, loadingEpg: $loadingEpg, selectedGroup: $selectedGroup, error: $error)';
  }
}

/// @nodoc
abstract mixin class $LivePlayerUiStateCopyWith<$Res> {
  factory $LivePlayerUiStateCopyWith(
    LivePlayerUiState value,
    $Res Function(LivePlayerUiState) _then,
  ) = _$LivePlayerUiStateCopyWithImpl;
  @useResult
  $Res call({
    LiveChannel currentChannel,
    LiveSource currentSource,
    List<LiveChannel> channels,
    List<LiveSource> sources,
    List<EpgProgram>? programs,
    bool loadingEpg,
    String selectedGroup,
    String? error,
  });
}

/// @nodoc
class _$LivePlayerUiStateCopyWithImpl<$Res>
    implements $LivePlayerUiStateCopyWith<$Res> {
  _$LivePlayerUiStateCopyWithImpl(this._self, this._then);

  final LivePlayerUiState _self;
  final $Res Function(LivePlayerUiState) _then;

  /// Create a copy of LivePlayerUiState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentChannel = null,
    Object? currentSource = null,
    Object? channels = null,
    Object? sources = null,
    Object? programs = freezed,
    Object? loadingEpg = null,
    Object? selectedGroup = null,
    Object? error = freezed,
  }) {
    return _then(
      _self.copyWith(
        currentChannel: null == currentChannel
            ? _self.currentChannel
            : currentChannel // ignore: cast_nullable_to_non_nullable
                  as LiveChannel,
        currentSource: null == currentSource
            ? _self.currentSource
            : currentSource // ignore: cast_nullable_to_non_nullable
                  as LiveSource,
        channels: null == channels
            ? _self.channels
            : channels // ignore: cast_nullable_to_non_nullable
                  as List<LiveChannel>,
        sources: null == sources
            ? _self.sources
            : sources // ignore: cast_nullable_to_non_nullable
                  as List<LiveSource>,
        programs: freezed == programs
            ? _self.programs
            : programs // ignore: cast_nullable_to_non_nullable
                  as List<EpgProgram>?,
        loadingEpg: null == loadingEpg
            ? _self.loadingEpg
            : loadingEpg // ignore: cast_nullable_to_non_nullable
                  as bool,
        selectedGroup: null == selectedGroup
            ? _self.selectedGroup
            : selectedGroup // ignore: cast_nullable_to_non_nullable
                  as String,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [LivePlayerUiState].
extension LivePlayerUiStatePatterns on LivePlayerUiState {
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
    TResult Function(_LivePlayerUiState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LivePlayerUiState() when $default != null:
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
    TResult Function(_LivePlayerUiState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LivePlayerUiState():
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
    TResult? Function(_LivePlayerUiState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LivePlayerUiState() when $default != null:
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
      LiveChannel currentChannel,
      LiveSource currentSource,
      List<LiveChannel> channels,
      List<LiveSource> sources,
      List<EpgProgram>? programs,
      bool loadingEpg,
      String selectedGroup,
      String? error,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LivePlayerUiState() when $default != null:
        return $default(
          _that.currentChannel,
          _that.currentSource,
          _that.channels,
          _that.sources,
          _that.programs,
          _that.loadingEpg,
          _that.selectedGroup,
          _that.error,
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
      LiveChannel currentChannel,
      LiveSource currentSource,
      List<LiveChannel> channels,
      List<LiveSource> sources,
      List<EpgProgram>? programs,
      bool loadingEpg,
      String selectedGroup,
      String? error,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LivePlayerUiState():
        return $default(
          _that.currentChannel,
          _that.currentSource,
          _that.channels,
          _that.sources,
          _that.programs,
          _that.loadingEpg,
          _that.selectedGroup,
          _that.error,
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
      LiveChannel currentChannel,
      LiveSource currentSource,
      List<LiveChannel> channels,
      List<LiveSource> sources,
      List<EpgProgram>? programs,
      bool loadingEpg,
      String selectedGroup,
      String? error,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LivePlayerUiState() when $default != null:
        return $default(
          _that.currentChannel,
          _that.currentSource,
          _that.channels,
          _that.sources,
          _that.programs,
          _that.loadingEpg,
          _that.selectedGroup,
          _that.error,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _LivePlayerUiState extends LivePlayerUiState {
  const _LivePlayerUiState({
    required this.currentChannel,
    required this.currentSource,
    final List<LiveChannel> channels = const <LiveChannel>[],
    final List<LiveSource> sources = const <LiveSource>[],
    final List<EpgProgram>? programs,
    this.loadingEpg = false,
    this.selectedGroup = '全部',
    this.error,
  }) : _channels = channels,
       _sources = sources,
       _programs = programs,
       super._();

  @override
  final LiveChannel currentChannel;
  @override
  final LiveSource currentSource;
  final List<LiveChannel> _channels;
  @override
  @JsonKey()
  List<LiveChannel> get channels {
    if (_channels is EqualUnmodifiableListView) return _channels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_channels);
  }

  final List<LiveSource> _sources;
  @override
  @JsonKey()
  List<LiveSource> get sources {
    if (_sources is EqualUnmodifiableListView) return _sources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sources);
  }

  final List<EpgProgram>? _programs;
  @override
  List<EpgProgram>? get programs {
    final value = _programs;
    if (value == null) return null;
    if (_programs is EqualUnmodifiableListView) return _programs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey()
  final bool loadingEpg;
  @override
  @JsonKey()
  final String selectedGroup;
  @override
  final String? error;

  /// Create a copy of LivePlayerUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LivePlayerUiStateCopyWith<_LivePlayerUiState> get copyWith =>
      __$LivePlayerUiStateCopyWithImpl<_LivePlayerUiState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LivePlayerUiState &&
            (identical(other.currentChannel, currentChannel) ||
                other.currentChannel == currentChannel) &&
            (identical(other.currentSource, currentSource) ||
                other.currentSource == currentSource) &&
            const DeepCollectionEquality().equals(other._channels, _channels) &&
            const DeepCollectionEquality().equals(other._sources, _sources) &&
            const DeepCollectionEquality().equals(other._programs, _programs) &&
            (identical(other.loadingEpg, loadingEpg) ||
                other.loadingEpg == loadingEpg) &&
            (identical(other.selectedGroup, selectedGroup) ||
                other.selectedGroup == selectedGroup) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    currentChannel,
    currentSource,
    const DeepCollectionEquality().hash(_channels),
    const DeepCollectionEquality().hash(_sources),
    const DeepCollectionEquality().hash(_programs),
    loadingEpg,
    selectedGroup,
    error,
  );

  @override
  String toString() {
    return 'LivePlayerUiState(currentChannel: $currentChannel, currentSource: $currentSource, channels: $channels, sources: $sources, programs: $programs, loadingEpg: $loadingEpg, selectedGroup: $selectedGroup, error: $error)';
  }
}

/// @nodoc
abstract mixin class _$LivePlayerUiStateCopyWith<$Res>
    implements $LivePlayerUiStateCopyWith<$Res> {
  factory _$LivePlayerUiStateCopyWith(
    _LivePlayerUiState value,
    $Res Function(_LivePlayerUiState) _then,
  ) = __$LivePlayerUiStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    LiveChannel currentChannel,
    LiveSource currentSource,
    List<LiveChannel> channels,
    List<LiveSource> sources,
    List<EpgProgram>? programs,
    bool loadingEpg,
    String selectedGroup,
    String? error,
  });
}

/// @nodoc
class __$LivePlayerUiStateCopyWithImpl<$Res>
    implements _$LivePlayerUiStateCopyWith<$Res> {
  __$LivePlayerUiStateCopyWithImpl(this._self, this._then);

  final _LivePlayerUiState _self;
  final $Res Function(_LivePlayerUiState) _then;

  /// Create a copy of LivePlayerUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? currentChannel = null,
    Object? currentSource = null,
    Object? channels = null,
    Object? sources = null,
    Object? programs = freezed,
    Object? loadingEpg = null,
    Object? selectedGroup = null,
    Object? error = freezed,
  }) {
    return _then(
      _LivePlayerUiState(
        currentChannel: null == currentChannel
            ? _self.currentChannel
            : currentChannel // ignore: cast_nullable_to_non_nullable
                  as LiveChannel,
        currentSource: null == currentSource
            ? _self.currentSource
            : currentSource // ignore: cast_nullable_to_non_nullable
                  as LiveSource,
        channels: null == channels
            ? _self._channels
            : channels // ignore: cast_nullable_to_non_nullable
                  as List<LiveChannel>,
        sources: null == sources
            ? _self._sources
            : sources // ignore: cast_nullable_to_non_nullable
                  as List<LiveSource>,
        programs: freezed == programs
            ? _self._programs
            : programs // ignore: cast_nullable_to_non_nullable
                  as List<EpgProgram>?,
        loadingEpg: null == loadingEpg
            ? _self.loadingEpg
            : loadingEpg // ignore: cast_nullable_to_non_nullable
                  as bool,
        selectedGroup: null == selectedGroup
            ? _self.selectedGroup
            : selectedGroup // ignore: cast_nullable_to_non_nullable
                  as String,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}
