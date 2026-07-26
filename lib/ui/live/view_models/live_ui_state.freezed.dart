// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LiveUiState {
  List<LiveSource> get sources;
  List<LiveChannelGroup> get groups;
  LiveSource? get currentSource;
  String get selectedGroup;
  bool get loading;
  bool get refreshing;
  bool get initialLoad;
  String? get error;
  String? get notice;

  /// Create a copy of LiveUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LiveUiStateCopyWith<LiveUiState> get copyWith =>
      _$LiveUiStateCopyWithImpl<LiveUiState>(this as LiveUiState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LiveUiState &&
            const DeepCollectionEquality().equals(other.sources, sources) &&
            const DeepCollectionEquality().equals(other.groups, groups) &&
            (identical(other.currentSource, currentSource) ||
                other.currentSource == currentSource) &&
            (identical(other.selectedGroup, selectedGroup) ||
                other.selectedGroup == selectedGroup) &&
            (identical(other.loading, loading) || other.loading == loading) &&
            (identical(other.refreshing, refreshing) ||
                other.refreshing == refreshing) &&
            (identical(other.initialLoad, initialLoad) ||
                other.initialLoad == initialLoad) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.notice, notice) || other.notice == notice));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(sources),
    const DeepCollectionEquality().hash(groups),
    currentSource,
    selectedGroup,
    loading,
    refreshing,
    initialLoad,
    error,
    notice,
  );

  @override
  String toString() {
    return 'LiveUiState(sources: $sources, groups: $groups, currentSource: $currentSource, selectedGroup: $selectedGroup, loading: $loading, refreshing: $refreshing, initialLoad: $initialLoad, error: $error, notice: $notice)';
  }
}

/// @nodoc
abstract mixin class $LiveUiStateCopyWith<$Res> {
  factory $LiveUiStateCopyWith(
    LiveUiState value,
    $Res Function(LiveUiState) _then,
  ) = _$LiveUiStateCopyWithImpl;
  @useResult
  $Res call({
    List<LiveSource> sources,
    List<LiveChannelGroup> groups,
    LiveSource? currentSource,
    String selectedGroup,
    bool loading,
    bool refreshing,
    bool initialLoad,
    String? error,
    String? notice,
  });
}

/// @nodoc
class _$LiveUiStateCopyWithImpl<$Res> implements $LiveUiStateCopyWith<$Res> {
  _$LiveUiStateCopyWithImpl(this._self, this._then);

  final LiveUiState _self;
  final $Res Function(LiveUiState) _then;

  /// Create a copy of LiveUiState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sources = null,
    Object? groups = null,
    Object? currentSource = freezed,
    Object? selectedGroup = null,
    Object? loading = null,
    Object? refreshing = null,
    Object? initialLoad = null,
    Object? error = freezed,
    Object? notice = freezed,
  }) {
    return _then(
      _self.copyWith(
        sources: null == sources
            ? _self.sources
            : sources // ignore: cast_nullable_to_non_nullable
                  as List<LiveSource>,
        groups: null == groups
            ? _self.groups
            : groups // ignore: cast_nullable_to_non_nullable
                  as List<LiveChannelGroup>,
        currentSource: freezed == currentSource
            ? _self.currentSource
            : currentSource // ignore: cast_nullable_to_non_nullable
                  as LiveSource?,
        selectedGroup: null == selectedGroup
            ? _self.selectedGroup
            : selectedGroup // ignore: cast_nullable_to_non_nullable
                  as String,
        loading: null == loading
            ? _self.loading
            : loading // ignore: cast_nullable_to_non_nullable
                  as bool,
        refreshing: null == refreshing
            ? _self.refreshing
            : refreshing // ignore: cast_nullable_to_non_nullable
                  as bool,
        initialLoad: null == initialLoad
            ? _self.initialLoad
            : initialLoad // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        notice: freezed == notice
            ? _self.notice
            : notice // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [LiveUiState].
extension LiveUiStatePatterns on LiveUiState {
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
    TResult Function(_LiveUiState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveUiState() when $default != null:
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
    TResult Function(_LiveUiState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveUiState():
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
    TResult? Function(_LiveUiState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveUiState() when $default != null:
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
      List<LiveSource> sources,
      List<LiveChannelGroup> groups,
      LiveSource? currentSource,
      String selectedGroup,
      bool loading,
      bool refreshing,
      bool initialLoad,
      String? error,
      String? notice,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LiveUiState() when $default != null:
        return $default(
          _that.sources,
          _that.groups,
          _that.currentSource,
          _that.selectedGroup,
          _that.loading,
          _that.refreshing,
          _that.initialLoad,
          _that.error,
          _that.notice,
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
      List<LiveSource> sources,
      List<LiveChannelGroup> groups,
      LiveSource? currentSource,
      String selectedGroup,
      bool loading,
      bool refreshing,
      bool initialLoad,
      String? error,
      String? notice,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveUiState():
        return $default(
          _that.sources,
          _that.groups,
          _that.currentSource,
          _that.selectedGroup,
          _that.loading,
          _that.refreshing,
          _that.initialLoad,
          _that.error,
          _that.notice,
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
      List<LiveSource> sources,
      List<LiveChannelGroup> groups,
      LiveSource? currentSource,
      String selectedGroup,
      bool loading,
      bool refreshing,
      bool initialLoad,
      String? error,
      String? notice,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LiveUiState() when $default != null:
        return $default(
          _that.sources,
          _that.groups,
          _that.currentSource,
          _that.selectedGroup,
          _that.loading,
          _that.refreshing,
          _that.initialLoad,
          _that.error,
          _that.notice,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _LiveUiState extends LiveUiState {
  const _LiveUiState({
    final List<LiveSource> sources = const <LiveSource>[],
    final List<LiveChannelGroup> groups = const <LiveChannelGroup>[],
    this.currentSource,
    this.selectedGroup = '全部',
    this.loading = true,
    this.refreshing = false,
    this.initialLoad = true,
    this.error,
    this.notice,
  }) : _sources = sources,
       _groups = groups,
       super._();

  final List<LiveSource> _sources;
  @override
  @JsonKey()
  List<LiveSource> get sources {
    if (_sources is EqualUnmodifiableListView) return _sources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sources);
  }

  final List<LiveChannelGroup> _groups;
  @override
  @JsonKey()
  List<LiveChannelGroup> get groups {
    if (_groups is EqualUnmodifiableListView) return _groups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_groups);
  }

  @override
  final LiveSource? currentSource;
  @override
  @JsonKey()
  final String selectedGroup;
  @override
  @JsonKey()
  final bool loading;
  @override
  @JsonKey()
  final bool refreshing;
  @override
  @JsonKey()
  final bool initialLoad;
  @override
  final String? error;
  @override
  final String? notice;

  /// Create a copy of LiveUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LiveUiStateCopyWith<_LiveUiState> get copyWith =>
      __$LiveUiStateCopyWithImpl<_LiveUiState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LiveUiState &&
            const DeepCollectionEquality().equals(other._sources, _sources) &&
            const DeepCollectionEquality().equals(other._groups, _groups) &&
            (identical(other.currentSource, currentSource) ||
                other.currentSource == currentSource) &&
            (identical(other.selectedGroup, selectedGroup) ||
                other.selectedGroup == selectedGroup) &&
            (identical(other.loading, loading) || other.loading == loading) &&
            (identical(other.refreshing, refreshing) ||
                other.refreshing == refreshing) &&
            (identical(other.initialLoad, initialLoad) ||
                other.initialLoad == initialLoad) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.notice, notice) || other.notice == notice));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_sources),
    const DeepCollectionEquality().hash(_groups),
    currentSource,
    selectedGroup,
    loading,
    refreshing,
    initialLoad,
    error,
    notice,
  );

  @override
  String toString() {
    return 'LiveUiState(sources: $sources, groups: $groups, currentSource: $currentSource, selectedGroup: $selectedGroup, loading: $loading, refreshing: $refreshing, initialLoad: $initialLoad, error: $error, notice: $notice)';
  }
}

/// @nodoc
abstract mixin class _$LiveUiStateCopyWith<$Res>
    implements $LiveUiStateCopyWith<$Res> {
  factory _$LiveUiStateCopyWith(
    _LiveUiState value,
    $Res Function(_LiveUiState) _then,
  ) = __$LiveUiStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    List<LiveSource> sources,
    List<LiveChannelGroup> groups,
    LiveSource? currentSource,
    String selectedGroup,
    bool loading,
    bool refreshing,
    bool initialLoad,
    String? error,
    String? notice,
  });
}

/// @nodoc
class __$LiveUiStateCopyWithImpl<$Res> implements _$LiveUiStateCopyWith<$Res> {
  __$LiveUiStateCopyWithImpl(this._self, this._then);

  final _LiveUiState _self;
  final $Res Function(_LiveUiState) _then;

  /// Create a copy of LiveUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? sources = null,
    Object? groups = null,
    Object? currentSource = freezed,
    Object? selectedGroup = null,
    Object? loading = null,
    Object? refreshing = null,
    Object? initialLoad = null,
    Object? error = freezed,
    Object? notice = freezed,
  }) {
    return _then(
      _LiveUiState(
        sources: null == sources
            ? _self._sources
            : sources // ignore: cast_nullable_to_non_nullable
                  as List<LiveSource>,
        groups: null == groups
            ? _self._groups
            : groups // ignore: cast_nullable_to_non_nullable
                  as List<LiveChannelGroup>,
        currentSource: freezed == currentSource
            ? _self.currentSource
            : currentSource // ignore: cast_nullable_to_non_nullable
                  as LiveSource?,
        selectedGroup: null == selectedGroup
            ? _self.selectedGroup
            : selectedGroup // ignore: cast_nullable_to_non_nullable
                  as String,
        loading: null == loading
            ? _self.loading
            : loading // ignore: cast_nullable_to_non_nullable
                  as bool,
        refreshing: null == refreshing
            ? _self.refreshing
            : refreshing // ignore: cast_nullable_to_non_nullable
                  as bool,
        initialLoad: null == initialLoad
            ? _self.initialLoad
            : initialLoad // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        notice: freezed == notice
            ? _self.notice
            : notice // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}
