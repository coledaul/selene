// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SearchUiState {
  String get query;
  List<String> get history;
  List<SearchResult> get results;
  SearchStatus get status;
  bool get aggregatedView;
  String get selectedSource;
  String get selectedYear;
  String get selectedTitle;
  SearchSortOrder get sortOrder;
  SearchProgress? get progress;
  String? get error;
  String? get warning;

  /// Create a copy of SearchUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SearchUiStateCopyWith<SearchUiState> get copyWith =>
      _$SearchUiStateCopyWithImpl<SearchUiState>(
        this as SearchUiState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SearchUiState &&
            (identical(other.query, query) || other.query == query) &&
            const DeepCollectionEquality().equals(other.history, history) &&
            const DeepCollectionEquality().equals(other.results, results) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.aggregatedView, aggregatedView) ||
                other.aggregatedView == aggregatedView) &&
            (identical(other.selectedSource, selectedSource) ||
                other.selectedSource == selectedSource) &&
            (identical(other.selectedYear, selectedYear) ||
                other.selectedYear == selectedYear) &&
            (identical(other.selectedTitle, selectedTitle) ||
                other.selectedTitle == selectedTitle) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.warning, warning) || other.warning == warning));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    query,
    const DeepCollectionEquality().hash(history),
    const DeepCollectionEquality().hash(results),
    status,
    aggregatedView,
    selectedSource,
    selectedYear,
    selectedTitle,
    sortOrder,
    progress,
    error,
    warning,
  );

  @override
  String toString() {
    return 'SearchUiState(query: $query, history: $history, results: $results, status: $status, aggregatedView: $aggregatedView, selectedSource: $selectedSource, selectedYear: $selectedYear, selectedTitle: $selectedTitle, sortOrder: $sortOrder, progress: $progress, error: $error, warning: $warning)';
  }
}

/// @nodoc
abstract mixin class $SearchUiStateCopyWith<$Res> {
  factory $SearchUiStateCopyWith(
    SearchUiState value,
    $Res Function(SearchUiState) _then,
  ) = _$SearchUiStateCopyWithImpl;
  @useResult
  $Res call({
    String query,
    List<String> history,
    List<SearchResult> results,
    SearchStatus status,
    bool aggregatedView,
    String selectedSource,
    String selectedYear,
    String selectedTitle,
    SearchSortOrder sortOrder,
    SearchProgress? progress,
    String? error,
    String? warning,
  });

  $SearchProgressCopyWith<$Res>? get progress;
}

/// @nodoc
class _$SearchUiStateCopyWithImpl<$Res>
    implements $SearchUiStateCopyWith<$Res> {
  _$SearchUiStateCopyWithImpl(this._self, this._then);

  final SearchUiState _self;
  final $Res Function(SearchUiState) _then;

  /// Create a copy of SearchUiState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = null,
    Object? history = null,
    Object? results = null,
    Object? status = null,
    Object? aggregatedView = null,
    Object? selectedSource = null,
    Object? selectedYear = null,
    Object? selectedTitle = null,
    Object? sortOrder = null,
    Object? progress = freezed,
    Object? error = freezed,
    Object? warning = freezed,
  }) {
    return _then(
      _self.copyWith(
        query: null == query
            ? _self.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
        history: null == history
            ? _self.history
            : history // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        results: null == results
            ? _self.results
            : results // ignore: cast_nullable_to_non_nullable
                  as List<SearchResult>,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as SearchStatus,
        aggregatedView: null == aggregatedView
            ? _self.aggregatedView
            : aggregatedView // ignore: cast_nullable_to_non_nullable
                  as bool,
        selectedSource: null == selectedSource
            ? _self.selectedSource
            : selectedSource // ignore: cast_nullable_to_non_nullable
                  as String,
        selectedYear: null == selectedYear
            ? _self.selectedYear
            : selectedYear // ignore: cast_nullable_to_non_nullable
                  as String,
        selectedTitle: null == selectedTitle
            ? _self.selectedTitle
            : selectedTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        sortOrder: null == sortOrder
            ? _self.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as SearchSortOrder,
        progress: freezed == progress
            ? _self.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as SearchProgress?,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        warning: freezed == warning
            ? _self.warning
            : warning // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of SearchUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SearchProgressCopyWith<$Res>? get progress {
    if (_self.progress == null) {
      return null;
    }

    return $SearchProgressCopyWith<$Res>(_self.progress!, (value) {
      return _then(_self.copyWith(progress: value));
    });
  }
}

/// Adds pattern-matching-related methods to [SearchUiState].
extension SearchUiStatePatterns on SearchUiState {
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
    TResult Function(_SearchUiState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SearchUiState() when $default != null:
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
    TResult Function(_SearchUiState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SearchUiState():
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
    TResult? Function(_SearchUiState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SearchUiState() when $default != null:
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
      String query,
      List<String> history,
      List<SearchResult> results,
      SearchStatus status,
      bool aggregatedView,
      String selectedSource,
      String selectedYear,
      String selectedTitle,
      SearchSortOrder sortOrder,
      SearchProgress? progress,
      String? error,
      String? warning,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SearchUiState() when $default != null:
        return $default(
          _that.query,
          _that.history,
          _that.results,
          _that.status,
          _that.aggregatedView,
          _that.selectedSource,
          _that.selectedYear,
          _that.selectedTitle,
          _that.sortOrder,
          _that.progress,
          _that.error,
          _that.warning,
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
      String query,
      List<String> history,
      List<SearchResult> results,
      SearchStatus status,
      bool aggregatedView,
      String selectedSource,
      String selectedYear,
      String selectedTitle,
      SearchSortOrder sortOrder,
      SearchProgress? progress,
      String? error,
      String? warning,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SearchUiState():
        return $default(
          _that.query,
          _that.history,
          _that.results,
          _that.status,
          _that.aggregatedView,
          _that.selectedSource,
          _that.selectedYear,
          _that.selectedTitle,
          _that.sortOrder,
          _that.progress,
          _that.error,
          _that.warning,
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
      String query,
      List<String> history,
      List<SearchResult> results,
      SearchStatus status,
      bool aggregatedView,
      String selectedSource,
      String selectedYear,
      String selectedTitle,
      SearchSortOrder sortOrder,
      SearchProgress? progress,
      String? error,
      String? warning,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SearchUiState() when $default != null:
        return $default(
          _that.query,
          _that.history,
          _that.results,
          _that.status,
          _that.aggregatedView,
          _that.selectedSource,
          _that.selectedYear,
          _that.selectedTitle,
          _that.sortOrder,
          _that.progress,
          _that.error,
          _that.warning,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _SearchUiState extends SearchUiState {
  const _SearchUiState({
    this.query = '',
    final List<String> history = const <String>[],
    final List<SearchResult> results = const <SearchResult>[],
    this.status = SearchStatus.idle,
    this.aggregatedView = true,
    this.selectedSource = 'all',
    this.selectedYear = 'all',
    this.selectedTitle = 'all',
    this.sortOrder = SearchSortOrder.none,
    this.progress,
    this.error,
    this.warning,
  }) : _history = history,
       _results = results,
       super._();

  @override
  @JsonKey()
  final String query;
  final List<String> _history;
  @override
  @JsonKey()
  List<String> get history {
    if (_history is EqualUnmodifiableListView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_history);
  }

  final List<SearchResult> _results;
  @override
  @JsonKey()
  List<SearchResult> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  @JsonKey()
  final SearchStatus status;
  @override
  @JsonKey()
  final bool aggregatedView;
  @override
  @JsonKey()
  final String selectedSource;
  @override
  @JsonKey()
  final String selectedYear;
  @override
  @JsonKey()
  final String selectedTitle;
  @override
  @JsonKey()
  final SearchSortOrder sortOrder;
  @override
  final SearchProgress? progress;
  @override
  final String? error;
  @override
  final String? warning;

  /// Create a copy of SearchUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SearchUiStateCopyWith<_SearchUiState> get copyWith =>
      __$SearchUiStateCopyWithImpl<_SearchUiState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SearchUiState &&
            (identical(other.query, query) || other.query == query) &&
            const DeepCollectionEquality().equals(other._history, _history) &&
            const DeepCollectionEquality().equals(other._results, _results) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.aggregatedView, aggregatedView) ||
                other.aggregatedView == aggregatedView) &&
            (identical(other.selectedSource, selectedSource) ||
                other.selectedSource == selectedSource) &&
            (identical(other.selectedYear, selectedYear) ||
                other.selectedYear == selectedYear) &&
            (identical(other.selectedTitle, selectedTitle) ||
                other.selectedTitle == selectedTitle) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.warning, warning) || other.warning == warning));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    query,
    const DeepCollectionEquality().hash(_history),
    const DeepCollectionEquality().hash(_results),
    status,
    aggregatedView,
    selectedSource,
    selectedYear,
    selectedTitle,
    sortOrder,
    progress,
    error,
    warning,
  );

  @override
  String toString() {
    return 'SearchUiState(query: $query, history: $history, results: $results, status: $status, aggregatedView: $aggregatedView, selectedSource: $selectedSource, selectedYear: $selectedYear, selectedTitle: $selectedTitle, sortOrder: $sortOrder, progress: $progress, error: $error, warning: $warning)';
  }
}

/// @nodoc
abstract mixin class _$SearchUiStateCopyWith<$Res>
    implements $SearchUiStateCopyWith<$Res> {
  factory _$SearchUiStateCopyWith(
    _SearchUiState value,
    $Res Function(_SearchUiState) _then,
  ) = __$SearchUiStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    String query,
    List<String> history,
    List<SearchResult> results,
    SearchStatus status,
    bool aggregatedView,
    String selectedSource,
    String selectedYear,
    String selectedTitle,
    SearchSortOrder sortOrder,
    SearchProgress? progress,
    String? error,
    String? warning,
  });

  @override
  $SearchProgressCopyWith<$Res>? get progress;
}

/// @nodoc
class __$SearchUiStateCopyWithImpl<$Res>
    implements _$SearchUiStateCopyWith<$Res> {
  __$SearchUiStateCopyWithImpl(this._self, this._then);

  final _SearchUiState _self;
  final $Res Function(_SearchUiState) _then;

  /// Create a copy of SearchUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? query = null,
    Object? history = null,
    Object? results = null,
    Object? status = null,
    Object? aggregatedView = null,
    Object? selectedSource = null,
    Object? selectedYear = null,
    Object? selectedTitle = null,
    Object? sortOrder = null,
    Object? progress = freezed,
    Object? error = freezed,
    Object? warning = freezed,
  }) {
    return _then(
      _SearchUiState(
        query: null == query
            ? _self.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
        history: null == history
            ? _self._history
            : history // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        results: null == results
            ? _self._results
            : results // ignore: cast_nullable_to_non_nullable
                  as List<SearchResult>,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as SearchStatus,
        aggregatedView: null == aggregatedView
            ? _self.aggregatedView
            : aggregatedView // ignore: cast_nullable_to_non_nullable
                  as bool,
        selectedSource: null == selectedSource
            ? _self.selectedSource
            : selectedSource // ignore: cast_nullable_to_non_nullable
                  as String,
        selectedYear: null == selectedYear
            ? _self.selectedYear
            : selectedYear // ignore: cast_nullable_to_non_nullable
                  as String,
        selectedTitle: null == selectedTitle
            ? _self.selectedTitle
            : selectedTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        sortOrder: null == sortOrder
            ? _self.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as SearchSortOrder,
        progress: freezed == progress
            ? _self.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as SearchProgress?,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        warning: freezed == warning
            ? _self.warning
            : warning // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of SearchUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SearchProgressCopyWith<$Res>? get progress {
    if (_self.progress == null) {
      return null;
    }

    return $SearchProgressCopyWith<$Res>(_self.progress!, (value) {
      return _then(_self.copyWith(progress: value));
    });
  }
}
