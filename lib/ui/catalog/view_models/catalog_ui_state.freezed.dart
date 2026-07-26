// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CatalogUiState {
  List<DoubanMovie> get items;
  String get category;
  String get secondary;
  String get type;
  String get region;
  String get year;
  String get platform;
  String get sort;
  int get page;
  bool get loading;
  bool get loadingMore;
  bool get hasMore;
  String? get error;

  /// Create a copy of CatalogUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CatalogUiStateCopyWith<CatalogUiState> get copyWith =>
      _$CatalogUiStateCopyWithImpl<CatalogUiState>(
        this as CatalogUiState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CatalogUiState &&
            const DeepCollectionEquality().equals(other.items, items) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.secondary, secondary) ||
                other.secondary == secondary) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.sort, sort) || other.sort == sort) &&
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
    const DeepCollectionEquality().hash(items),
    category,
    secondary,
    type,
    region,
    year,
    platform,
    sort,
    page,
    loading,
    loadingMore,
    hasMore,
    error,
  );

  @override
  String toString() {
    return 'CatalogUiState(items: $items, category: $category, secondary: $secondary, type: $type, region: $region, year: $year, platform: $platform, sort: $sort, page: $page, loading: $loading, loadingMore: $loadingMore, hasMore: $hasMore, error: $error)';
  }
}

/// @nodoc
abstract mixin class $CatalogUiStateCopyWith<$Res> {
  factory $CatalogUiStateCopyWith(
    CatalogUiState value,
    $Res Function(CatalogUiState) _then,
  ) = _$CatalogUiStateCopyWithImpl;
  @useResult
  $Res call({
    List<DoubanMovie> items,
    String category,
    String secondary,
    String type,
    String region,
    String year,
    String platform,
    String sort,
    int page,
    bool loading,
    bool loadingMore,
    bool hasMore,
    String? error,
  });
}

/// @nodoc
class _$CatalogUiStateCopyWithImpl<$Res>
    implements $CatalogUiStateCopyWith<$Res> {
  _$CatalogUiStateCopyWithImpl(this._self, this._then);

  final CatalogUiState _self;
  final $Res Function(CatalogUiState) _then;

  /// Create a copy of CatalogUiState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? category = null,
    Object? secondary = null,
    Object? type = null,
    Object? region = null,
    Object? year = null,
    Object? platform = null,
    Object? sort = null,
    Object? page = null,
    Object? loading = null,
    Object? loadingMore = null,
    Object? hasMore = null,
    Object? error = freezed,
  }) {
    return _then(
      _self.copyWith(
        items: null == items
            ? _self.items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<DoubanMovie>,
        category: null == category
            ? _self.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        secondary: null == secondary
            ? _self.secondary
            : secondary // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _self.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        region: null == region
            ? _self.region
            : region // ignore: cast_nullable_to_non_nullable
                  as String,
        year: null == year
            ? _self.year
            : year // ignore: cast_nullable_to_non_nullable
                  as String,
        platform: null == platform
            ? _self.platform
            : platform // ignore: cast_nullable_to_non_nullable
                  as String,
        sort: null == sort
            ? _self.sort
            : sort // ignore: cast_nullable_to_non_nullable
                  as String,
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

/// Adds pattern-matching-related methods to [CatalogUiState].
extension CatalogUiStatePatterns on CatalogUiState {
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
    TResult Function(_CatalogUiState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CatalogUiState() when $default != null:
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
    TResult Function(_CatalogUiState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CatalogUiState():
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
    TResult? Function(_CatalogUiState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CatalogUiState() when $default != null:
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
      List<DoubanMovie> items,
      String category,
      String secondary,
      String type,
      String region,
      String year,
      String platform,
      String sort,
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
      case _CatalogUiState() when $default != null:
        return $default(
          _that.items,
          _that.category,
          _that.secondary,
          _that.type,
          _that.region,
          _that.year,
          _that.platform,
          _that.sort,
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
      List<DoubanMovie> items,
      String category,
      String secondary,
      String type,
      String region,
      String year,
      String platform,
      String sort,
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
      case _CatalogUiState():
        return $default(
          _that.items,
          _that.category,
          _that.secondary,
          _that.type,
          _that.region,
          _that.year,
          _that.platform,
          _that.sort,
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
      List<DoubanMovie> items,
      String category,
      String secondary,
      String type,
      String region,
      String year,
      String platform,
      String sort,
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
      case _CatalogUiState() when $default != null:
        return $default(
          _that.items,
          _that.category,
          _that.secondary,
          _that.type,
          _that.region,
          _that.year,
          _that.platform,
          _that.sort,
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

class _CatalogUiState implements CatalogUiState {
  const _CatalogUiState({
    final List<DoubanMovie> items = const <DoubanMovie>[],
    required this.category,
    required this.secondary,
    this.type = 'all',
    this.region = 'all',
    this.year = 'all',
    this.platform = 'all',
    this.sort = 'T',
    this.page = 0,
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = true,
    this.error,
  }) : _items = items;

  final List<DoubanMovie> _items;
  @override
  @JsonKey()
  List<DoubanMovie> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final String category;
  @override
  final String secondary;
  @override
  @JsonKey()
  final String type;
  @override
  @JsonKey()
  final String region;
  @override
  @JsonKey()
  final String year;
  @override
  @JsonKey()
  final String platform;
  @override
  @JsonKey()
  final String sort;
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

  /// Create a copy of CatalogUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CatalogUiStateCopyWith<_CatalogUiState> get copyWith =>
      __$CatalogUiStateCopyWithImpl<_CatalogUiState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CatalogUiState &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.secondary, secondary) ||
                other.secondary == secondary) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.sort, sort) || other.sort == sort) &&
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
    const DeepCollectionEquality().hash(_items),
    category,
    secondary,
    type,
    region,
    year,
    platform,
    sort,
    page,
    loading,
    loadingMore,
    hasMore,
    error,
  );

  @override
  String toString() {
    return 'CatalogUiState(items: $items, category: $category, secondary: $secondary, type: $type, region: $region, year: $year, platform: $platform, sort: $sort, page: $page, loading: $loading, loadingMore: $loadingMore, hasMore: $hasMore, error: $error)';
  }
}

/// @nodoc
abstract mixin class _$CatalogUiStateCopyWith<$Res>
    implements $CatalogUiStateCopyWith<$Res> {
  factory _$CatalogUiStateCopyWith(
    _CatalogUiState value,
    $Res Function(_CatalogUiState) _then,
  ) = __$CatalogUiStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    List<DoubanMovie> items,
    String category,
    String secondary,
    String type,
    String region,
    String year,
    String platform,
    String sort,
    int page,
    bool loading,
    bool loadingMore,
    bool hasMore,
    String? error,
  });
}

/// @nodoc
class __$CatalogUiStateCopyWithImpl<$Res>
    implements _$CatalogUiStateCopyWith<$Res> {
  __$CatalogUiStateCopyWithImpl(this._self, this._then);

  final _CatalogUiState _self;
  final $Res Function(_CatalogUiState) _then;

  /// Create a copy of CatalogUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? items = null,
    Object? category = null,
    Object? secondary = null,
    Object? type = null,
    Object? region = null,
    Object? year = null,
    Object? platform = null,
    Object? sort = null,
    Object? page = null,
    Object? loading = null,
    Object? loadingMore = null,
    Object? hasMore = null,
    Object? error = freezed,
  }) {
    return _then(
      _CatalogUiState(
        items: null == items
            ? _self._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<DoubanMovie>,
        category: null == category
            ? _self.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        secondary: null == secondary
            ? _self.secondary
            : secondary // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _self.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        region: null == region
            ? _self.region
            : region // ignore: cast_nullable_to_non_nullable
                  as String,
        year: null == year
            ? _self.year
            : year // ignore: cast_nullable_to_non_nullable
                  as String,
        platform: null == platform
            ? _self.platform
            : platform // ignore: cast_nullable_to_non_nullable
                  as String,
        sort: null == sort
            ? _self.sort
            : sort // ignore: cast_nullable_to_non_nullable
                  as String,
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
