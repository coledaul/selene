// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HomeUiState {
  int get bottomNavigationIndex;
  int get topTabIndex;
  List<PlayRecord> get playRecords;
  List<FavoriteItem> get favorites;
  bool get playRecordsLoading;
  String? get playRecordsError;
  bool get favoritesLoading;
  String? get favoritesError;
  List<VideoInfo> get hotMovies;
  List<VideoInfo> get hotTvShows;
  List<VideoInfo> get hotShows;
  List<VideoInfo> get todayAnime;
  Set<String> get failedSections;
  Set<String> get loadingSections;
  AppVersionInfo? get availableUpdate;

  /// Create a copy of HomeUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HomeUiStateCopyWith<HomeUiState> get copyWith =>
      _$HomeUiStateCopyWithImpl<HomeUiState>(this as HomeUiState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HomeUiState &&
            (identical(other.bottomNavigationIndex, bottomNavigationIndex) ||
                other.bottomNavigationIndex == bottomNavigationIndex) &&
            (identical(other.topTabIndex, topTabIndex) ||
                other.topTabIndex == topTabIndex) &&
            const DeepCollectionEquality().equals(
              other.playRecords,
              playRecords,
            ) &&
            const DeepCollectionEquality().equals(other.favorites, favorites) &&
            (identical(other.playRecordsLoading, playRecordsLoading) ||
                other.playRecordsLoading == playRecordsLoading) &&
            (identical(other.playRecordsError, playRecordsError) ||
                other.playRecordsError == playRecordsError) &&
            (identical(other.favoritesLoading, favoritesLoading) ||
                other.favoritesLoading == favoritesLoading) &&
            (identical(other.favoritesError, favoritesError) ||
                other.favoritesError == favoritesError) &&
            const DeepCollectionEquality().equals(other.hotMovies, hotMovies) &&
            const DeepCollectionEquality().equals(
              other.hotTvShows,
              hotTvShows,
            ) &&
            const DeepCollectionEquality().equals(other.hotShows, hotShows) &&
            const DeepCollectionEquality().equals(
              other.todayAnime,
              todayAnime,
            ) &&
            const DeepCollectionEquality().equals(
              other.failedSections,
              failedSections,
            ) &&
            const DeepCollectionEquality().equals(
              other.loadingSections,
              loadingSections,
            ) &&
            (identical(other.availableUpdate, availableUpdate) ||
                other.availableUpdate == availableUpdate));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    bottomNavigationIndex,
    topTabIndex,
    const DeepCollectionEquality().hash(playRecords),
    const DeepCollectionEquality().hash(favorites),
    playRecordsLoading,
    playRecordsError,
    favoritesLoading,
    favoritesError,
    const DeepCollectionEquality().hash(hotMovies),
    const DeepCollectionEquality().hash(hotTvShows),
    const DeepCollectionEquality().hash(hotShows),
    const DeepCollectionEquality().hash(todayAnime),
    const DeepCollectionEquality().hash(failedSections),
    const DeepCollectionEquality().hash(loadingSections),
    availableUpdate,
  );

  @override
  String toString() {
    return 'HomeUiState(bottomNavigationIndex: $bottomNavigationIndex, topTabIndex: $topTabIndex, playRecords: $playRecords, favorites: $favorites, playRecordsLoading: $playRecordsLoading, playRecordsError: $playRecordsError, favoritesLoading: $favoritesLoading, favoritesError: $favoritesError, hotMovies: $hotMovies, hotTvShows: $hotTvShows, hotShows: $hotShows, todayAnime: $todayAnime, failedSections: $failedSections, loadingSections: $loadingSections, availableUpdate: $availableUpdate)';
  }
}

/// @nodoc
abstract mixin class $HomeUiStateCopyWith<$Res> {
  factory $HomeUiStateCopyWith(
    HomeUiState value,
    $Res Function(HomeUiState) _then,
  ) = _$HomeUiStateCopyWithImpl;
  @useResult
  $Res call({
    int bottomNavigationIndex,
    int topTabIndex,
    List<PlayRecord> playRecords,
    List<FavoriteItem> favorites,
    bool playRecordsLoading,
    String? playRecordsError,
    bool favoritesLoading,
    String? favoritesError,
    List<VideoInfo> hotMovies,
    List<VideoInfo> hotTvShows,
    List<VideoInfo> hotShows,
    List<VideoInfo> todayAnime,
    Set<String> failedSections,
    Set<String> loadingSections,
    AppVersionInfo? availableUpdate,
  });

  $AppVersionInfoCopyWith<$Res>? get availableUpdate;
}

/// @nodoc
class _$HomeUiStateCopyWithImpl<$Res> implements $HomeUiStateCopyWith<$Res> {
  _$HomeUiStateCopyWithImpl(this._self, this._then);

  final HomeUiState _self;
  final $Res Function(HomeUiState) _then;

  /// Create a copy of HomeUiState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bottomNavigationIndex = null,
    Object? topTabIndex = null,
    Object? playRecords = null,
    Object? favorites = null,
    Object? playRecordsLoading = null,
    Object? playRecordsError = freezed,
    Object? favoritesLoading = null,
    Object? favoritesError = freezed,
    Object? hotMovies = null,
    Object? hotTvShows = null,
    Object? hotShows = null,
    Object? todayAnime = null,
    Object? failedSections = null,
    Object? loadingSections = null,
    Object? availableUpdate = freezed,
  }) {
    return _then(
      _self.copyWith(
        bottomNavigationIndex: null == bottomNavigationIndex
            ? _self.bottomNavigationIndex
            : bottomNavigationIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        topTabIndex: null == topTabIndex
            ? _self.topTabIndex
            : topTabIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        playRecords: null == playRecords
            ? _self.playRecords
            : playRecords // ignore: cast_nullable_to_non_nullable
                  as List<PlayRecord>,
        favorites: null == favorites
            ? _self.favorites
            : favorites // ignore: cast_nullable_to_non_nullable
                  as List<FavoriteItem>,
        playRecordsLoading: null == playRecordsLoading
            ? _self.playRecordsLoading
            : playRecordsLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        playRecordsError: freezed == playRecordsError
            ? _self.playRecordsError
            : playRecordsError // ignore: cast_nullable_to_non_nullable
                  as String?,
        favoritesLoading: null == favoritesLoading
            ? _self.favoritesLoading
            : favoritesLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        favoritesError: freezed == favoritesError
            ? _self.favoritesError
            : favoritesError // ignore: cast_nullable_to_non_nullable
                  as String?,
        hotMovies: null == hotMovies
            ? _self.hotMovies
            : hotMovies // ignore: cast_nullable_to_non_nullable
                  as List<VideoInfo>,
        hotTvShows: null == hotTvShows
            ? _self.hotTvShows
            : hotTvShows // ignore: cast_nullable_to_non_nullable
                  as List<VideoInfo>,
        hotShows: null == hotShows
            ? _self.hotShows
            : hotShows // ignore: cast_nullable_to_non_nullable
                  as List<VideoInfo>,
        todayAnime: null == todayAnime
            ? _self.todayAnime
            : todayAnime // ignore: cast_nullable_to_non_nullable
                  as List<VideoInfo>,
        failedSections: null == failedSections
            ? _self.failedSections
            : failedSections // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
        loadingSections: null == loadingSections
            ? _self.loadingSections
            : loadingSections // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
        availableUpdate: freezed == availableUpdate
            ? _self.availableUpdate
            : availableUpdate // ignore: cast_nullable_to_non_nullable
                  as AppVersionInfo?,
      ),
    );
  }

  /// Create a copy of HomeUiState
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

/// Adds pattern-matching-related methods to [HomeUiState].
extension HomeUiStatePatterns on HomeUiState {
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
    TResult Function(_HomeUiState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HomeUiState() when $default != null:
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
    TResult Function(_HomeUiState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HomeUiState():
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
    TResult? Function(_HomeUiState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HomeUiState() when $default != null:
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
      int bottomNavigationIndex,
      int topTabIndex,
      List<PlayRecord> playRecords,
      List<FavoriteItem> favorites,
      bool playRecordsLoading,
      String? playRecordsError,
      bool favoritesLoading,
      String? favoritesError,
      List<VideoInfo> hotMovies,
      List<VideoInfo> hotTvShows,
      List<VideoInfo> hotShows,
      List<VideoInfo> todayAnime,
      Set<String> failedSections,
      Set<String> loadingSections,
      AppVersionInfo? availableUpdate,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HomeUiState() when $default != null:
        return $default(
          _that.bottomNavigationIndex,
          _that.topTabIndex,
          _that.playRecords,
          _that.favorites,
          _that.playRecordsLoading,
          _that.playRecordsError,
          _that.favoritesLoading,
          _that.favoritesError,
          _that.hotMovies,
          _that.hotTvShows,
          _that.hotShows,
          _that.todayAnime,
          _that.failedSections,
          _that.loadingSections,
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
      int bottomNavigationIndex,
      int topTabIndex,
      List<PlayRecord> playRecords,
      List<FavoriteItem> favorites,
      bool playRecordsLoading,
      String? playRecordsError,
      bool favoritesLoading,
      String? favoritesError,
      List<VideoInfo> hotMovies,
      List<VideoInfo> hotTvShows,
      List<VideoInfo> hotShows,
      List<VideoInfo> todayAnime,
      Set<String> failedSections,
      Set<String> loadingSections,
      AppVersionInfo? availableUpdate,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HomeUiState():
        return $default(
          _that.bottomNavigationIndex,
          _that.topTabIndex,
          _that.playRecords,
          _that.favorites,
          _that.playRecordsLoading,
          _that.playRecordsError,
          _that.favoritesLoading,
          _that.favoritesError,
          _that.hotMovies,
          _that.hotTvShows,
          _that.hotShows,
          _that.todayAnime,
          _that.failedSections,
          _that.loadingSections,
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
      int bottomNavigationIndex,
      int topTabIndex,
      List<PlayRecord> playRecords,
      List<FavoriteItem> favorites,
      bool playRecordsLoading,
      String? playRecordsError,
      bool favoritesLoading,
      String? favoritesError,
      List<VideoInfo> hotMovies,
      List<VideoInfo> hotTvShows,
      List<VideoInfo> hotShows,
      List<VideoInfo> todayAnime,
      Set<String> failedSections,
      Set<String> loadingSections,
      AppVersionInfo? availableUpdate,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HomeUiState() when $default != null:
        return $default(
          _that.bottomNavigationIndex,
          _that.topTabIndex,
          _that.playRecords,
          _that.favorites,
          _that.playRecordsLoading,
          _that.playRecordsError,
          _that.favoritesLoading,
          _that.favoritesError,
          _that.hotMovies,
          _that.hotTvShows,
          _that.hotShows,
          _that.todayAnime,
          _that.failedSections,
          _that.loadingSections,
          _that.availableUpdate,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _HomeUiState implements HomeUiState {
  const _HomeUiState({
    this.bottomNavigationIndex = 0,
    this.topTabIndex = 0,
    final List<PlayRecord> playRecords = const <PlayRecord>[],
    final List<FavoriteItem> favorites = const <FavoriteItem>[],
    this.playRecordsLoading = false,
    this.playRecordsError,
    this.favoritesLoading = false,
    this.favoritesError,
    final List<VideoInfo> hotMovies = const <VideoInfo>[],
    final List<VideoInfo> hotTvShows = const <VideoInfo>[],
    final List<VideoInfo> hotShows = const <VideoInfo>[],
    final List<VideoInfo> todayAnime = const <VideoInfo>[],
    final Set<String> failedSections = const <String>{},
    final Set<String> loadingSections = const <String>{},
    this.availableUpdate,
  }) : _playRecords = playRecords,
       _favorites = favorites,
       _hotMovies = hotMovies,
       _hotTvShows = hotTvShows,
       _hotShows = hotShows,
       _todayAnime = todayAnime,
       _failedSections = failedSections,
       _loadingSections = loadingSections;

  @override
  @JsonKey()
  final int bottomNavigationIndex;
  @override
  @JsonKey()
  final int topTabIndex;
  final List<PlayRecord> _playRecords;
  @override
  @JsonKey()
  List<PlayRecord> get playRecords {
    if (_playRecords is EqualUnmodifiableListView) return _playRecords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_playRecords);
  }

  final List<FavoriteItem> _favorites;
  @override
  @JsonKey()
  List<FavoriteItem> get favorites {
    if (_favorites is EqualUnmodifiableListView) return _favorites;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_favorites);
  }

  @override
  @JsonKey()
  final bool playRecordsLoading;
  @override
  final String? playRecordsError;
  @override
  @JsonKey()
  final bool favoritesLoading;
  @override
  final String? favoritesError;
  final List<VideoInfo> _hotMovies;
  @override
  @JsonKey()
  List<VideoInfo> get hotMovies {
    if (_hotMovies is EqualUnmodifiableListView) return _hotMovies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hotMovies);
  }

  final List<VideoInfo> _hotTvShows;
  @override
  @JsonKey()
  List<VideoInfo> get hotTvShows {
    if (_hotTvShows is EqualUnmodifiableListView) return _hotTvShows;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hotTvShows);
  }

  final List<VideoInfo> _hotShows;
  @override
  @JsonKey()
  List<VideoInfo> get hotShows {
    if (_hotShows is EqualUnmodifiableListView) return _hotShows;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hotShows);
  }

  final List<VideoInfo> _todayAnime;
  @override
  @JsonKey()
  List<VideoInfo> get todayAnime {
    if (_todayAnime is EqualUnmodifiableListView) return _todayAnime;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_todayAnime);
  }

  final Set<String> _failedSections;
  @override
  @JsonKey()
  Set<String> get failedSections {
    if (_failedSections is EqualUnmodifiableSetView) return _failedSections;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_failedSections);
  }

  final Set<String> _loadingSections;
  @override
  @JsonKey()
  Set<String> get loadingSections {
    if (_loadingSections is EqualUnmodifiableSetView) return _loadingSections;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_loadingSections);
  }

  @override
  final AppVersionInfo? availableUpdate;

  /// Create a copy of HomeUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HomeUiStateCopyWith<_HomeUiState> get copyWith =>
      __$HomeUiStateCopyWithImpl<_HomeUiState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HomeUiState &&
            (identical(other.bottomNavigationIndex, bottomNavigationIndex) ||
                other.bottomNavigationIndex == bottomNavigationIndex) &&
            (identical(other.topTabIndex, topTabIndex) ||
                other.topTabIndex == topTabIndex) &&
            const DeepCollectionEquality().equals(
              other._playRecords,
              _playRecords,
            ) &&
            const DeepCollectionEquality().equals(
              other._favorites,
              _favorites,
            ) &&
            (identical(other.playRecordsLoading, playRecordsLoading) ||
                other.playRecordsLoading == playRecordsLoading) &&
            (identical(other.playRecordsError, playRecordsError) ||
                other.playRecordsError == playRecordsError) &&
            (identical(other.favoritesLoading, favoritesLoading) ||
                other.favoritesLoading == favoritesLoading) &&
            (identical(other.favoritesError, favoritesError) ||
                other.favoritesError == favoritesError) &&
            const DeepCollectionEquality().equals(
              other._hotMovies,
              _hotMovies,
            ) &&
            const DeepCollectionEquality().equals(
              other._hotTvShows,
              _hotTvShows,
            ) &&
            const DeepCollectionEquality().equals(other._hotShows, _hotShows) &&
            const DeepCollectionEquality().equals(
              other._todayAnime,
              _todayAnime,
            ) &&
            const DeepCollectionEquality().equals(
              other._failedSections,
              _failedSections,
            ) &&
            const DeepCollectionEquality().equals(
              other._loadingSections,
              _loadingSections,
            ) &&
            (identical(other.availableUpdate, availableUpdate) ||
                other.availableUpdate == availableUpdate));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    bottomNavigationIndex,
    topTabIndex,
    const DeepCollectionEquality().hash(_playRecords),
    const DeepCollectionEquality().hash(_favorites),
    playRecordsLoading,
    playRecordsError,
    favoritesLoading,
    favoritesError,
    const DeepCollectionEquality().hash(_hotMovies),
    const DeepCollectionEquality().hash(_hotTvShows),
    const DeepCollectionEquality().hash(_hotShows),
    const DeepCollectionEquality().hash(_todayAnime),
    const DeepCollectionEquality().hash(_failedSections),
    const DeepCollectionEquality().hash(_loadingSections),
    availableUpdate,
  );

  @override
  String toString() {
    return 'HomeUiState(bottomNavigationIndex: $bottomNavigationIndex, topTabIndex: $topTabIndex, playRecords: $playRecords, favorites: $favorites, playRecordsLoading: $playRecordsLoading, playRecordsError: $playRecordsError, favoritesLoading: $favoritesLoading, favoritesError: $favoritesError, hotMovies: $hotMovies, hotTvShows: $hotTvShows, hotShows: $hotShows, todayAnime: $todayAnime, failedSections: $failedSections, loadingSections: $loadingSections, availableUpdate: $availableUpdate)';
  }
}

/// @nodoc
abstract mixin class _$HomeUiStateCopyWith<$Res>
    implements $HomeUiStateCopyWith<$Res> {
  factory _$HomeUiStateCopyWith(
    _HomeUiState value,
    $Res Function(_HomeUiState) _then,
  ) = __$HomeUiStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    int bottomNavigationIndex,
    int topTabIndex,
    List<PlayRecord> playRecords,
    List<FavoriteItem> favorites,
    bool playRecordsLoading,
    String? playRecordsError,
    bool favoritesLoading,
    String? favoritesError,
    List<VideoInfo> hotMovies,
    List<VideoInfo> hotTvShows,
    List<VideoInfo> hotShows,
    List<VideoInfo> todayAnime,
    Set<String> failedSections,
    Set<String> loadingSections,
    AppVersionInfo? availableUpdate,
  });

  @override
  $AppVersionInfoCopyWith<$Res>? get availableUpdate;
}

/// @nodoc
class __$HomeUiStateCopyWithImpl<$Res> implements _$HomeUiStateCopyWith<$Res> {
  __$HomeUiStateCopyWithImpl(this._self, this._then);

  final _HomeUiState _self;
  final $Res Function(_HomeUiState) _then;

  /// Create a copy of HomeUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? bottomNavigationIndex = null,
    Object? topTabIndex = null,
    Object? playRecords = null,
    Object? favorites = null,
    Object? playRecordsLoading = null,
    Object? playRecordsError = freezed,
    Object? favoritesLoading = null,
    Object? favoritesError = freezed,
    Object? hotMovies = null,
    Object? hotTvShows = null,
    Object? hotShows = null,
    Object? todayAnime = null,
    Object? failedSections = null,
    Object? loadingSections = null,
    Object? availableUpdate = freezed,
  }) {
    return _then(
      _HomeUiState(
        bottomNavigationIndex: null == bottomNavigationIndex
            ? _self.bottomNavigationIndex
            : bottomNavigationIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        topTabIndex: null == topTabIndex
            ? _self.topTabIndex
            : topTabIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        playRecords: null == playRecords
            ? _self._playRecords
            : playRecords // ignore: cast_nullable_to_non_nullable
                  as List<PlayRecord>,
        favorites: null == favorites
            ? _self._favorites
            : favorites // ignore: cast_nullable_to_non_nullable
                  as List<FavoriteItem>,
        playRecordsLoading: null == playRecordsLoading
            ? _self.playRecordsLoading
            : playRecordsLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        playRecordsError: freezed == playRecordsError
            ? _self.playRecordsError
            : playRecordsError // ignore: cast_nullable_to_non_nullable
                  as String?,
        favoritesLoading: null == favoritesLoading
            ? _self.favoritesLoading
            : favoritesLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        favoritesError: freezed == favoritesError
            ? _self.favoritesError
            : favoritesError // ignore: cast_nullable_to_non_nullable
                  as String?,
        hotMovies: null == hotMovies
            ? _self._hotMovies
            : hotMovies // ignore: cast_nullable_to_non_nullable
                  as List<VideoInfo>,
        hotTvShows: null == hotTvShows
            ? _self._hotTvShows
            : hotTvShows // ignore: cast_nullable_to_non_nullable
                  as List<VideoInfo>,
        hotShows: null == hotShows
            ? _self._hotShows
            : hotShows // ignore: cast_nullable_to_non_nullable
                  as List<VideoInfo>,
        todayAnime: null == todayAnime
            ? _self._todayAnime
            : todayAnime // ignore: cast_nullable_to_non_nullable
                  as List<VideoInfo>,
        failedSections: null == failedSections
            ? _self._failedSections
            : failedSections // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
        loadingSections: null == loadingSections
            ? _self._loadingSections
            : loadingSections // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
        availableUpdate: freezed == availableUpdate
            ? _self.availableUpdate
            : availableUpdate // ignore: cast_nullable_to_non_nullable
                  as AppVersionInfo?,
      ),
    );
  }

  /// Create a copy of HomeUiState
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
