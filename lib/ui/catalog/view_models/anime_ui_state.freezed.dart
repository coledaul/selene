// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'anime_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AnimeUiState {
  String get category;
  String get weekday;
  String get animeType;
  String get animeRegion;
  String get animeYear;
  String get animePlatform;
  String get animeSort;
  String get movieType;
  String get movieRegion;
  String get movieYear;
  String get movieSort;
  List<DoubanMovie> get animeItems;
  List<BangumiItem> get calendarItems;
  int get page;
  bool get loading;
  bool get loadingMore;
  bool get hasMore;
  String? get error;

  /// Create a copy of AnimeUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AnimeUiStateCopyWith<AnimeUiState> get copyWith =>
      _$AnimeUiStateCopyWithImpl<AnimeUiState>(
        this as AnimeUiState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AnimeUiState &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.weekday, weekday) || other.weekday == weekday) &&
            (identical(other.animeType, animeType) ||
                other.animeType == animeType) &&
            (identical(other.animeRegion, animeRegion) ||
                other.animeRegion == animeRegion) &&
            (identical(other.animeYear, animeYear) ||
                other.animeYear == animeYear) &&
            (identical(other.animePlatform, animePlatform) ||
                other.animePlatform == animePlatform) &&
            (identical(other.animeSort, animeSort) ||
                other.animeSort == animeSort) &&
            (identical(other.movieType, movieType) ||
                other.movieType == movieType) &&
            (identical(other.movieRegion, movieRegion) ||
                other.movieRegion == movieRegion) &&
            (identical(other.movieYear, movieYear) ||
                other.movieYear == movieYear) &&
            (identical(other.movieSort, movieSort) ||
                other.movieSort == movieSort) &&
            const DeepCollectionEquality().equals(
              other.animeItems,
              animeItems,
            ) &&
            const DeepCollectionEquality().equals(
              other.calendarItems,
              calendarItems,
            ) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.loading, loading) || other.loading == loading) &&
            (identical(other.loadingMore, loadingMore) ||
                other.loadingMore == loadingMore) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    category,
    weekday,
    animeType,
    animeRegion,
    animeYear,
    animePlatform,
    animeSort,
    movieType,
    movieRegion,
    movieYear,
    movieSort,
    const DeepCollectionEquality().hash(animeItems),
    const DeepCollectionEquality().hash(calendarItems),
    page,
    loading,
    loadingMore,
    hasMore,
    error,
  );

  @override
  String toString() {
    return 'AnimeUiState(category: $category, weekday: $weekday, animeType: $animeType, animeRegion: $animeRegion, animeYear: $animeYear, animePlatform: $animePlatform, animeSort: $animeSort, movieType: $movieType, movieRegion: $movieRegion, movieYear: $movieYear, movieSort: $movieSort, animeItems: $animeItems, calendarItems: $calendarItems, page: $page, loading: $loading, loadingMore: $loadingMore, hasMore: $hasMore, error: $error)';
  }
}

/// @nodoc
abstract mixin class $AnimeUiStateCopyWith<$Res> {
  factory $AnimeUiStateCopyWith(
    AnimeUiState value,
    $Res Function(AnimeUiState) _then,
  ) = _$AnimeUiStateCopyWithImpl;
  @useResult
  $Res call({
    String category,
    String weekday,
    String animeType,
    String animeRegion,
    String animeYear,
    String animePlatform,
    String animeSort,
    String movieType,
    String movieRegion,
    String movieYear,
    String movieSort,
    List<DoubanMovie> animeItems,
    List<BangumiItem> calendarItems,
    int page,
    bool loading,
    bool loadingMore,
    bool hasMore,
    String? error,
  });
}

/// @nodoc
class _$AnimeUiStateCopyWithImpl<$Res> implements $AnimeUiStateCopyWith<$Res> {
  _$AnimeUiStateCopyWithImpl(this._self, this._then);

  final AnimeUiState _self;
  final $Res Function(AnimeUiState) _then;

  /// Create a copy of AnimeUiState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? weekday = null,
    Object? animeType = null,
    Object? animeRegion = null,
    Object? animeYear = null,
    Object? animePlatform = null,
    Object? animeSort = null,
    Object? movieType = null,
    Object? movieRegion = null,
    Object? movieYear = null,
    Object? movieSort = null,
    Object? animeItems = null,
    Object? calendarItems = null,
    Object? page = null,
    Object? loading = null,
    Object? loadingMore = null,
    Object? hasMore = null,
    Object? error = freezed,
  }) {
    return _then(
      _self.copyWith(
        category: null == category
            ? _self.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        weekday: null == weekday
            ? _self.weekday
            : weekday // ignore: cast_nullable_to_non_nullable
                  as String,
        animeType: null == animeType
            ? _self.animeType
            : animeType // ignore: cast_nullable_to_non_nullable
                  as String,
        animeRegion: null == animeRegion
            ? _self.animeRegion
            : animeRegion // ignore: cast_nullable_to_non_nullable
                  as String,
        animeYear: null == animeYear
            ? _self.animeYear
            : animeYear // ignore: cast_nullable_to_non_nullable
                  as String,
        animePlatform: null == animePlatform
            ? _self.animePlatform
            : animePlatform // ignore: cast_nullable_to_non_nullable
                  as String,
        animeSort: null == animeSort
            ? _self.animeSort
            : animeSort // ignore: cast_nullable_to_non_nullable
                  as String,
        movieType: null == movieType
            ? _self.movieType
            : movieType // ignore: cast_nullable_to_non_nullable
                  as String,
        movieRegion: null == movieRegion
            ? _self.movieRegion
            : movieRegion // ignore: cast_nullable_to_non_nullable
                  as String,
        movieYear: null == movieYear
            ? _self.movieYear
            : movieYear // ignore: cast_nullable_to_non_nullable
                  as String,
        movieSort: null == movieSort
            ? _self.movieSort
            : movieSort // ignore: cast_nullable_to_non_nullable
                  as String,
        animeItems: null == animeItems
            ? _self.animeItems
            : animeItems // ignore: cast_nullable_to_non_nullable
                  as List<DoubanMovie>,
        calendarItems: null == calendarItems
            ? _self.calendarItems
            : calendarItems // ignore: cast_nullable_to_non_nullable
                  as List<BangumiItem>,
        page: null == page
            ? _self.page
            : page // ignore: cast_nullable_to_non_nullable
                  as int,
        loading: null == loading
            ? _self.loading
            : loading // ignore: cast_nullable_to_non_nullable
                  as bool,
        loadingMore: null == loadingMore
            ? _self.loadingMore
            : loadingMore // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasMore: null == hasMore
            ? _self.hasMore
            : hasMore // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [AnimeUiState].
extension AnimeUiStatePatterns on AnimeUiState {
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
    TResult Function(_AnimeUiState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AnimeUiState() when $default != null:
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
    TResult Function(_AnimeUiState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AnimeUiState():
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
    TResult? Function(_AnimeUiState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AnimeUiState() when $default != null:
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
      String category,
      String weekday,
      String animeType,
      String animeRegion,
      String animeYear,
      String animePlatform,
      String animeSort,
      String movieType,
      String movieRegion,
      String movieYear,
      String movieSort,
      List<DoubanMovie> animeItems,
      List<BangumiItem> calendarItems,
      int page,
      bool loading,
      bool loadingMore,
      bool hasMore,
      String? error,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AnimeUiState() when $default != null:
        return $default(
          _that.category,
          _that.weekday,
          _that.animeType,
          _that.animeRegion,
          _that.animeYear,
          _that.animePlatform,
          _that.animeSort,
          _that.movieType,
          _that.movieRegion,
          _that.movieYear,
          _that.movieSort,
          _that.animeItems,
          _that.calendarItems,
          _that.page,
          _that.loading,
          _that.loadingMore,
          _that.hasMore,
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
      String category,
      String weekday,
      String animeType,
      String animeRegion,
      String animeYear,
      String animePlatform,
      String animeSort,
      String movieType,
      String movieRegion,
      String movieYear,
      String movieSort,
      List<DoubanMovie> animeItems,
      List<BangumiItem> calendarItems,
      int page,
      bool loading,
      bool loadingMore,
      bool hasMore,
      String? error,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AnimeUiState():
        return $default(
          _that.category,
          _that.weekday,
          _that.animeType,
          _that.animeRegion,
          _that.animeYear,
          _that.animePlatform,
          _that.animeSort,
          _that.movieType,
          _that.movieRegion,
          _that.movieYear,
          _that.movieSort,
          _that.animeItems,
          _that.calendarItems,
          _that.page,
          _that.loading,
          _that.loadingMore,
          _that.hasMore,
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
      String category,
      String weekday,
      String animeType,
      String animeRegion,
      String animeYear,
      String animePlatform,
      String animeSort,
      String movieType,
      String movieRegion,
      String movieYear,
      String movieSort,
      List<DoubanMovie> animeItems,
      List<BangumiItem> calendarItems,
      int page,
      bool loading,
      bool loadingMore,
      bool hasMore,
      String? error,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AnimeUiState() when $default != null:
        return $default(
          _that.category,
          _that.weekday,
          _that.animeType,
          _that.animeRegion,
          _that.animeYear,
          _that.animePlatform,
          _that.animeSort,
          _that.movieType,
          _that.movieRegion,
          _that.movieYear,
          _that.movieSort,
          _that.animeItems,
          _that.calendarItems,
          _that.page,
          _that.loading,
          _that.loadingMore,
          _that.hasMore,
          _that.error,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _AnimeUiState implements AnimeUiState {
  const _AnimeUiState({
    this.category = '每日放送',
    required this.weekday,
    this.animeType = 'all',
    this.animeRegion = 'all',
    this.animeYear = 'all',
    this.animePlatform = 'all',
    this.animeSort = 'T',
    this.movieType = 'all',
    this.movieRegion = 'all',
    this.movieYear = 'all',
    this.movieSort = 'T',
    final List<DoubanMovie> animeItems = const <DoubanMovie>[],
    final List<BangumiItem> calendarItems = const <BangumiItem>[],
    this.page = 0,
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = true,
    this.error,
  }) : _animeItems = animeItems,
       _calendarItems = calendarItems;

  @override
  @JsonKey()
  final String category;
  @override
  final String weekday;
  @override
  @JsonKey()
  final String animeType;
  @override
  @JsonKey()
  final String animeRegion;
  @override
  @JsonKey()
  final String animeYear;
  @override
  @JsonKey()
  final String animePlatform;
  @override
  @JsonKey()
  final String animeSort;
  @override
  @JsonKey()
  final String movieType;
  @override
  @JsonKey()
  final String movieRegion;
  @override
  @JsonKey()
  final String movieYear;
  @override
  @JsonKey()
  final String movieSort;
  final List<DoubanMovie> _animeItems;
  @override
  @JsonKey()
  List<DoubanMovie> get animeItems {
    if (_animeItems is EqualUnmodifiableListView) return _animeItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_animeItems);
  }

  final List<BangumiItem> _calendarItems;
  @override
  @JsonKey()
  List<BangumiItem> get calendarItems {
    if (_calendarItems is EqualUnmodifiableListView) return _calendarItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_calendarItems);
  }

  @override
  @JsonKey()
  final int page;
  @override
  @JsonKey()
  final bool loading;
  @override
  @JsonKey()
  final bool loadingMore;
  @override
  @JsonKey()
  final bool hasMore;
  @override
  final String? error;

  /// Create a copy of AnimeUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AnimeUiStateCopyWith<_AnimeUiState> get copyWith =>
      __$AnimeUiStateCopyWithImpl<_AnimeUiState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AnimeUiState &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.weekday, weekday) || other.weekday == weekday) &&
            (identical(other.animeType, animeType) ||
                other.animeType == animeType) &&
            (identical(other.animeRegion, animeRegion) ||
                other.animeRegion == animeRegion) &&
            (identical(other.animeYear, animeYear) ||
                other.animeYear == animeYear) &&
            (identical(other.animePlatform, animePlatform) ||
                other.animePlatform == animePlatform) &&
            (identical(other.animeSort, animeSort) ||
                other.animeSort == animeSort) &&
            (identical(other.movieType, movieType) ||
                other.movieType == movieType) &&
            (identical(other.movieRegion, movieRegion) ||
                other.movieRegion == movieRegion) &&
            (identical(other.movieYear, movieYear) ||
                other.movieYear == movieYear) &&
            (identical(other.movieSort, movieSort) ||
                other.movieSort == movieSort) &&
            const DeepCollectionEquality().equals(
              other._animeItems,
              _animeItems,
            ) &&
            const DeepCollectionEquality().equals(
              other._calendarItems,
              _calendarItems,
            ) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.loading, loading) || other.loading == loading) &&
            (identical(other.loadingMore, loadingMore) ||
                other.loadingMore == loadingMore) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    category,
    weekday,
    animeType,
    animeRegion,
    animeYear,
    animePlatform,
    animeSort,
    movieType,
    movieRegion,
    movieYear,
    movieSort,
    const DeepCollectionEquality().hash(_animeItems),
    const DeepCollectionEquality().hash(_calendarItems),
    page,
    loading,
    loadingMore,
    hasMore,
    error,
  );

  @override
  String toString() {
    return 'AnimeUiState(category: $category, weekday: $weekday, animeType: $animeType, animeRegion: $animeRegion, animeYear: $animeYear, animePlatform: $animePlatform, animeSort: $animeSort, movieType: $movieType, movieRegion: $movieRegion, movieYear: $movieYear, movieSort: $movieSort, animeItems: $animeItems, calendarItems: $calendarItems, page: $page, loading: $loading, loadingMore: $loadingMore, hasMore: $hasMore, error: $error)';
  }
}

/// @nodoc
abstract mixin class _$AnimeUiStateCopyWith<$Res>
    implements $AnimeUiStateCopyWith<$Res> {
  factory _$AnimeUiStateCopyWith(
    _AnimeUiState value,
    $Res Function(_AnimeUiState) _then,
  ) = __$AnimeUiStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    String category,
    String weekday,
    String animeType,
    String animeRegion,
    String animeYear,
    String animePlatform,
    String animeSort,
    String movieType,
    String movieRegion,
    String movieYear,
    String movieSort,
    List<DoubanMovie> animeItems,
    List<BangumiItem> calendarItems,
    int page,
    bool loading,
    bool loadingMore,
    bool hasMore,
    String? error,
  });
}

/// @nodoc
class __$AnimeUiStateCopyWithImpl<$Res>
    implements _$AnimeUiStateCopyWith<$Res> {
  __$AnimeUiStateCopyWithImpl(this._self, this._then);

  final _AnimeUiState _self;
  final $Res Function(_AnimeUiState) _then;

  /// Create a copy of AnimeUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? category = null,
    Object? weekday = null,
    Object? animeType = null,
    Object? animeRegion = null,
    Object? animeYear = null,
    Object? animePlatform = null,
    Object? animeSort = null,
    Object? movieType = null,
    Object? movieRegion = null,
    Object? movieYear = null,
    Object? movieSort = null,
    Object? animeItems = null,
    Object? calendarItems = null,
    Object? page = null,
    Object? loading = null,
    Object? loadingMore = null,
    Object? hasMore = null,
    Object? error = freezed,
  }) {
    return _then(
      _AnimeUiState(
        category: null == category
            ? _self.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        weekday: null == weekday
            ? _self.weekday
            : weekday // ignore: cast_nullable_to_non_nullable
                  as String,
        animeType: null == animeType
            ? _self.animeType
            : animeType // ignore: cast_nullable_to_non_nullable
                  as String,
        animeRegion: null == animeRegion
            ? _self.animeRegion
            : animeRegion // ignore: cast_nullable_to_non_nullable
                  as String,
        animeYear: null == animeYear
            ? _self.animeYear
            : animeYear // ignore: cast_nullable_to_non_nullable
                  as String,
        animePlatform: null == animePlatform
            ? _self.animePlatform
            : animePlatform // ignore: cast_nullable_to_non_nullable
                  as String,
        animeSort: null == animeSort
            ? _self.animeSort
            : animeSort // ignore: cast_nullable_to_non_nullable
                  as String,
        movieType: null == movieType
            ? _self.movieType
            : movieType // ignore: cast_nullable_to_non_nullable
                  as String,
        movieRegion: null == movieRegion
            ? _self.movieRegion
            : movieRegion // ignore: cast_nullable_to_non_nullable
                  as String,
        movieYear: null == movieYear
            ? _self.movieYear
            : movieYear // ignore: cast_nullable_to_non_nullable
                  as String,
        movieSort: null == movieSort
            ? _self.movieSort
            : movieSort // ignore: cast_nullable_to_non_nullable
                  as String,
        animeItems: null == animeItems
            ? _self._animeItems
            : animeItems // ignore: cast_nullable_to_non_nullable
                  as List<DoubanMovie>,
        calendarItems: null == calendarItems
            ? _self._calendarItems
            : calendarItems // ignore: cast_nullable_to_non_nullable
                  as List<BangumiItem>,
        page: null == page
            ? _self.page
            : page // ignore: cast_nullable_to_non_nullable
                  as int,
        loading: null == loading
            ? _self.loading
            : loading // ignore: cast_nullable_to_non_nullable
                  as bool,
        loadingMore: null == loadingMore
            ? _self.loadingMore
            : loadingMore // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasMore: null == hasMore
            ? _self.hasMore
            : hasMore // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}
