// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_metadata_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VideoMetadataUiState {
  DoubanMovieDetails? get doubanDetails;
  BangumiDetails? get bangumiDetails;
  bool get loadingDouban;
  bool get loadingBangumi;
  String? get doubanError;
  String? get bangumiError;

  /// Create a copy of VideoMetadataUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $VideoMetadataUiStateCopyWith<VideoMetadataUiState> get copyWith =>
      _$VideoMetadataUiStateCopyWithImpl<VideoMetadataUiState>(
        this as VideoMetadataUiState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is VideoMetadataUiState &&
            (identical(other.doubanDetails, doubanDetails) ||
                other.doubanDetails == doubanDetails) &&
            (identical(other.bangumiDetails, bangumiDetails) ||
                other.bangumiDetails == bangumiDetails) &&
            (identical(other.loadingDouban, loadingDouban) ||
                other.loadingDouban == loadingDouban) &&
            (identical(other.loadingBangumi, loadingBangumi) ||
                other.loadingBangumi == loadingBangumi) &&
            (identical(other.doubanError, doubanError) ||
                other.doubanError == doubanError) &&
            (identical(other.bangumiError, bangumiError) ||
                other.bangumiError == bangumiError));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    doubanDetails,
    bangumiDetails,
    loadingDouban,
    loadingBangumi,
    doubanError,
    bangumiError,
  );

  @override
  String toString() {
    return 'VideoMetadataUiState(doubanDetails: $doubanDetails, bangumiDetails: $bangumiDetails, loadingDouban: $loadingDouban, loadingBangumi: $loadingBangumi, doubanError: $doubanError, bangumiError: $bangumiError)';
  }
}

/// @nodoc
abstract mixin class $VideoMetadataUiStateCopyWith<$Res> {
  factory $VideoMetadataUiStateCopyWith(
    VideoMetadataUiState value,
    $Res Function(VideoMetadataUiState) _then,
  ) = _$VideoMetadataUiStateCopyWithImpl;
  @useResult
  $Res call({
    DoubanMovieDetails? doubanDetails,
    BangumiDetails? bangumiDetails,
    bool loadingDouban,
    bool loadingBangumi,
    String? doubanError,
    String? bangumiError,
  });
}

/// @nodoc
class _$VideoMetadataUiStateCopyWithImpl<$Res>
    implements $VideoMetadataUiStateCopyWith<$Res> {
  _$VideoMetadataUiStateCopyWithImpl(this._self, this._then);

  final VideoMetadataUiState _self;
  final $Res Function(VideoMetadataUiState) _then;

  /// Create a copy of VideoMetadataUiState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? doubanDetails = freezed,
    Object? bangumiDetails = freezed,
    Object? loadingDouban = null,
    Object? loadingBangumi = null,
    Object? doubanError = freezed,
    Object? bangumiError = freezed,
  }) {
    return _then(
      _self.copyWith(
        doubanDetails: freezed == doubanDetails
            ? _self.doubanDetails
            : doubanDetails // ignore: cast_nullable_to_non_nullable
                  as DoubanMovieDetails?,
        bangumiDetails: freezed == bangumiDetails
            ? _self.bangumiDetails
            : bangumiDetails // ignore: cast_nullable_to_non_nullable
                  as BangumiDetails?,
        loadingDouban: null == loadingDouban
            ? _self.loadingDouban
            : loadingDouban // ignore: cast_nullable_to_non_nullable
                  as bool,
        loadingBangumi: null == loadingBangumi
            ? _self.loadingBangumi
            : loadingBangumi // ignore: cast_nullable_to_non_nullable
                  as bool,
        doubanError: freezed == doubanError
            ? _self.doubanError
            : doubanError // ignore: cast_nullable_to_non_nullable
                  as String?,
        bangumiError: freezed == bangumiError
            ? _self.bangumiError
            : bangumiError // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [VideoMetadataUiState].
extension VideoMetadataUiStatePatterns on VideoMetadataUiState {
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
    TResult Function(_VideoMetadataUiState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _VideoMetadataUiState() when $default != null:
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
    TResult Function(_VideoMetadataUiState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VideoMetadataUiState():
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
    TResult? Function(_VideoMetadataUiState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VideoMetadataUiState() when $default != null:
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
      DoubanMovieDetails? doubanDetails,
      BangumiDetails? bangumiDetails,
      bool loadingDouban,
      bool loadingBangumi,
      String? doubanError,
      String? bangumiError,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _VideoMetadataUiState() when $default != null:
        return $default(
          _that.doubanDetails,
          _that.bangumiDetails,
          _that.loadingDouban,
          _that.loadingBangumi,
          _that.doubanError,
          _that.bangumiError,
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
      DoubanMovieDetails? doubanDetails,
      BangumiDetails? bangumiDetails,
      bool loadingDouban,
      bool loadingBangumi,
      String? doubanError,
      String? bangumiError,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VideoMetadataUiState():
        return $default(
          _that.doubanDetails,
          _that.bangumiDetails,
          _that.loadingDouban,
          _that.loadingBangumi,
          _that.doubanError,
          _that.bangumiError,
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
      DoubanMovieDetails? doubanDetails,
      BangumiDetails? bangumiDetails,
      bool loadingDouban,
      bool loadingBangumi,
      String? doubanError,
      String? bangumiError,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VideoMetadataUiState() when $default != null:
        return $default(
          _that.doubanDetails,
          _that.bangumiDetails,
          _that.loadingDouban,
          _that.loadingBangumi,
          _that.doubanError,
          _that.bangumiError,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _VideoMetadataUiState implements VideoMetadataUiState {
  const _VideoMetadataUiState({
    this.doubanDetails,
    this.bangumiDetails,
    this.loadingDouban = false,
    this.loadingBangumi = false,
    this.doubanError,
    this.bangumiError,
  });

  @override
  final DoubanMovieDetails? doubanDetails;
  @override
  final BangumiDetails? bangumiDetails;
  @override
  @JsonKey()
  final bool loadingDouban;
  @override
  @JsonKey()
  final bool loadingBangumi;
  @override
  final String? doubanError;
  @override
  final String? bangumiError;

  /// Create a copy of VideoMetadataUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$VideoMetadataUiStateCopyWith<_VideoMetadataUiState> get copyWith =>
      __$VideoMetadataUiStateCopyWithImpl<_VideoMetadataUiState>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _VideoMetadataUiState &&
            (identical(other.doubanDetails, doubanDetails) ||
                other.doubanDetails == doubanDetails) &&
            (identical(other.bangumiDetails, bangumiDetails) ||
                other.bangumiDetails == bangumiDetails) &&
            (identical(other.loadingDouban, loadingDouban) ||
                other.loadingDouban == loadingDouban) &&
            (identical(other.loadingBangumi, loadingBangumi) ||
                other.loadingBangumi == loadingBangumi) &&
            (identical(other.doubanError, doubanError) ||
                other.doubanError == doubanError) &&
            (identical(other.bangumiError, bangumiError) ||
                other.bangumiError == bangumiError));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    doubanDetails,
    bangumiDetails,
    loadingDouban,
    loadingBangumi,
    doubanError,
    bangumiError,
  );

  @override
  String toString() {
    return 'VideoMetadataUiState(doubanDetails: $doubanDetails, bangumiDetails: $bangumiDetails, loadingDouban: $loadingDouban, loadingBangumi: $loadingBangumi, doubanError: $doubanError, bangumiError: $bangumiError)';
  }
}

/// @nodoc
abstract mixin class _$VideoMetadataUiStateCopyWith<$Res>
    implements $VideoMetadataUiStateCopyWith<$Res> {
  factory _$VideoMetadataUiStateCopyWith(
    _VideoMetadataUiState value,
    $Res Function(_VideoMetadataUiState) _then,
  ) = __$VideoMetadataUiStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    DoubanMovieDetails? doubanDetails,
    BangumiDetails? bangumiDetails,
    bool loadingDouban,
    bool loadingBangumi,
    String? doubanError,
    String? bangumiError,
  });
}

/// @nodoc
class __$VideoMetadataUiStateCopyWithImpl<$Res>
    implements _$VideoMetadataUiStateCopyWith<$Res> {
  __$VideoMetadataUiStateCopyWithImpl(this._self, this._then);

  final _VideoMetadataUiState _self;
  final $Res Function(_VideoMetadataUiState) _then;

  /// Create a copy of VideoMetadataUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? doubanDetails = freezed,
    Object? bangumiDetails = freezed,
    Object? loadingDouban = null,
    Object? loadingBangumi = null,
    Object? doubanError = freezed,
    Object? bangumiError = freezed,
  }) {
    return _then(
      _VideoMetadataUiState(
        doubanDetails: freezed == doubanDetails
            ? _self.doubanDetails
            : doubanDetails // ignore: cast_nullable_to_non_nullable
                  as DoubanMovieDetails?,
        bangumiDetails: freezed == bangumiDetails
            ? _self.bangumiDetails
            : bangumiDetails // ignore: cast_nullable_to_non_nullable
                  as BangumiDetails?,
        loadingDouban: null == loadingDouban
            ? _self.loadingDouban
            : loadingDouban // ignore: cast_nullable_to_non_nullable
                  as bool,
        loadingBangumi: null == loadingBangumi
            ? _self.loadingBangumi
            : loadingBangumi // ignore: cast_nullable_to_non_nullable
                  as bool,
        doubanError: freezed == doubanError
            ? _self.doubanError
            : doubanError // ignore: cast_nullable_to_non_nullable
                  as String?,
        bangumiError: freezed == bangumiError
            ? _self.bangumiError
            : bangumiError // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}
