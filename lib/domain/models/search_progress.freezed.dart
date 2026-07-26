// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SearchProgress {
  int get totalSources;
  int get completedSources;
  String? get currentSource;
  bool get isComplete;
  bool get isFailure;
  String? get error;

  /// Create a copy of SearchProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SearchProgressCopyWith<SearchProgress> get copyWith =>
      _$SearchProgressCopyWithImpl<SearchProgress>(
        this as SearchProgress,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SearchProgress &&
            (identical(other.totalSources, totalSources) ||
                other.totalSources == totalSources) &&
            (identical(other.completedSources, completedSources) ||
                other.completedSources == completedSources) &&
            (identical(other.currentSource, currentSource) ||
                other.currentSource == currentSource) &&
            (identical(other.isComplete, isComplete) ||
                other.isComplete == isComplete) &&
            (identical(other.isFailure, isFailure) ||
                other.isFailure == isFailure) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalSources,
    completedSources,
    currentSource,
    isComplete,
    isFailure,
    error,
  );

  @override
  String toString() {
    return 'SearchProgress(totalSources: $totalSources, completedSources: $completedSources, currentSource: $currentSource, isComplete: $isComplete, isFailure: $isFailure, error: $error)';
  }
}

/// @nodoc
abstract mixin class $SearchProgressCopyWith<$Res> {
  factory $SearchProgressCopyWith(
    SearchProgress value,
    $Res Function(SearchProgress) _then,
  ) = _$SearchProgressCopyWithImpl;
  @useResult
  $Res call({
    int totalSources,
    int completedSources,
    String? currentSource,
    bool isComplete,
    bool isFailure,
    String? error,
  });
}

/// @nodoc
class _$SearchProgressCopyWithImpl<$Res>
    implements $SearchProgressCopyWith<$Res> {
  _$SearchProgressCopyWithImpl(this._self, this._then);

  final SearchProgress _self;
  final $Res Function(SearchProgress) _then;

  /// Create a copy of SearchProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalSources = null,
    Object? completedSources = null,
    Object? currentSource = freezed,
    Object? isComplete = null,
    Object? isFailure = null,
    Object? error = freezed,
  }) {
    return _then(
      _self.copyWith(
        totalSources: null == totalSources
            ? _self.totalSources
            : totalSources // ignore: cast_nullable_to_non_nullable
                  as int,
        completedSources: null == completedSources
            ? _self.completedSources
            : completedSources // ignore: cast_nullable_to_non_nullable
                  as int,
        currentSource: freezed == currentSource
            ? _self.currentSource
            : currentSource // ignore: cast_nullable_to_non_nullable
                  as String?,
        isComplete: null == isComplete
            ? _self.isComplete
            : isComplete // ignore: cast_nullable_to_non_nullable
                  as bool,
        isFailure: null == isFailure
            ? _self.isFailure
            : isFailure // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [SearchProgress].
extension SearchProgressPatterns on SearchProgress {
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
    TResult Function(_SearchProgress value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SearchProgress() when $default != null:
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
    TResult Function(_SearchProgress value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SearchProgress():
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
    TResult? Function(_SearchProgress value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SearchProgress() when $default != null:
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
      int totalSources,
      int completedSources,
      String? currentSource,
      bool isComplete,
      bool isFailure,
      String? error,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SearchProgress() when $default != null:
        return $default(
          _that.totalSources,
          _that.completedSources,
          _that.currentSource,
          _that.isComplete,
          _that.isFailure,
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
      int totalSources,
      int completedSources,
      String? currentSource,
      bool isComplete,
      bool isFailure,
      String? error,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SearchProgress():
        return $default(
          _that.totalSources,
          _that.completedSources,
          _that.currentSource,
          _that.isComplete,
          _that.isFailure,
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
      int totalSources,
      int completedSources,
      String? currentSource,
      bool isComplete,
      bool isFailure,
      String? error,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SearchProgress() when $default != null:
        return $default(
          _that.totalSources,
          _that.completedSources,
          _that.currentSource,
          _that.isComplete,
          _that.isFailure,
          _that.error,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _SearchProgress extends SearchProgress {
  const _SearchProgress({
    required this.totalSources,
    required this.completedSources,
    this.currentSource,
    required this.isComplete,
    this.isFailure = false,
    this.error,
  }) : super._();

  @override
  final int totalSources;
  @override
  final int completedSources;
  @override
  final String? currentSource;
  @override
  final bool isComplete;
  @override
  @JsonKey()
  final bool isFailure;
  @override
  final String? error;

  /// Create a copy of SearchProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SearchProgressCopyWith<_SearchProgress> get copyWith =>
      __$SearchProgressCopyWithImpl<_SearchProgress>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SearchProgress &&
            (identical(other.totalSources, totalSources) ||
                other.totalSources == totalSources) &&
            (identical(other.completedSources, completedSources) ||
                other.completedSources == completedSources) &&
            (identical(other.currentSource, currentSource) ||
                other.currentSource == currentSource) &&
            (identical(other.isComplete, isComplete) ||
                other.isComplete == isComplete) &&
            (identical(other.isFailure, isFailure) ||
                other.isFailure == isFailure) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalSources,
    completedSources,
    currentSource,
    isComplete,
    isFailure,
    error,
  );

  @override
  String toString() {
    return 'SearchProgress(totalSources: $totalSources, completedSources: $completedSources, currentSource: $currentSource, isComplete: $isComplete, isFailure: $isFailure, error: $error)';
  }
}

/// @nodoc
abstract mixin class _$SearchProgressCopyWith<$Res>
    implements $SearchProgressCopyWith<$Res> {
  factory _$SearchProgressCopyWith(
    _SearchProgress value,
    $Res Function(_SearchProgress) _then,
  ) = __$SearchProgressCopyWithImpl;
  @override
  @useResult
  $Res call({
    int totalSources,
    int completedSources,
    String? currentSource,
    bool isComplete,
    bool isFailure,
    String? error,
  });
}

/// @nodoc
class __$SearchProgressCopyWithImpl<$Res>
    implements _$SearchProgressCopyWith<$Res> {
  __$SearchProgressCopyWithImpl(this._self, this._then);

  final _SearchProgress _self;
  final $Res Function(_SearchProgress) _then;

  /// Create a copy of SearchProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? totalSources = null,
    Object? completedSources = null,
    Object? currentSource = freezed,
    Object? isComplete = null,
    Object? isFailure = null,
    Object? error = freezed,
  }) {
    return _then(
      _SearchProgress(
        totalSources: null == totalSources
            ? _self.totalSources
            : totalSources // ignore: cast_nullable_to_non_nullable
                  as int,
        completedSources: null == completedSources
            ? _self.completedSources
            : completedSources // ignore: cast_nullable_to_non_nullable
                  as int,
        currentSource: freezed == currentSource
            ? _self.currentSource
            : currentSource // ignore: cast_nullable_to_non_nullable
                  as String?,
        isComplete: null == isComplete
            ? _self.isComplete
            : isComplete // ignore: cast_nullable_to_non_nullable
                  as bool,
        isFailure: null == isFailure
            ? _self.isFailure
            : isFailure // ignore: cast_nullable_to_non_nullable
                  as bool,
        error: freezed == error
            ? _self.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}
