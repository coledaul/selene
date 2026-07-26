// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubscriptionCandidate {
  String get url;
  List<SearchResource> get searchSources;
  List<LiveSource> get liveSources;
  bool get replacesExistingData;

  /// Create a copy of SubscriptionCandidate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SubscriptionCandidateCopyWith<SubscriptionCandidate> get copyWith =>
      _$SubscriptionCandidateCopyWithImpl<SubscriptionCandidate>(
        this as SubscriptionCandidate,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SubscriptionCandidate &&
            (identical(other.url, url) || other.url == url) &&
            const DeepCollectionEquality().equals(
              other.searchSources,
              searchSources,
            ) &&
            const DeepCollectionEquality().equals(
              other.liveSources,
              liveSources,
            ) &&
            (identical(other.replacesExistingData, replacesExistingData) ||
                other.replacesExistingData == replacesExistingData));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    url,
    const DeepCollectionEquality().hash(searchSources),
    const DeepCollectionEquality().hash(liveSources),
    replacesExistingData,
  );

  @override
  String toString() {
    return 'SubscriptionCandidate(url: $url, searchSources: $searchSources, liveSources: $liveSources, replacesExistingData: $replacesExistingData)';
  }
}

/// @nodoc
abstract mixin class $SubscriptionCandidateCopyWith<$Res> {
  factory $SubscriptionCandidateCopyWith(
    SubscriptionCandidate value,
    $Res Function(SubscriptionCandidate) _then,
  ) = _$SubscriptionCandidateCopyWithImpl;
  @useResult
  $Res call({
    String url,
    List<SearchResource> searchSources,
    List<LiveSource> liveSources,
    bool replacesExistingData,
  });
}

/// @nodoc
class _$SubscriptionCandidateCopyWithImpl<$Res>
    implements $SubscriptionCandidateCopyWith<$Res> {
  _$SubscriptionCandidateCopyWithImpl(this._self, this._then);

  final SubscriptionCandidate _self;
  final $Res Function(SubscriptionCandidate) _then;

  /// Create a copy of SubscriptionCandidate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? searchSources = null,
    Object? liveSources = null,
    Object? replacesExistingData = null,
  }) {
    return _then(
      _self.copyWith(
        url: null == url
            ? _self.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        searchSources: null == searchSources
            ? _self.searchSources
            : searchSources // ignore: cast_nullable_to_non_nullable
                  as List<SearchResource>,
        liveSources: null == liveSources
            ? _self.liveSources
            : liveSources // ignore: cast_nullable_to_non_nullable
                  as List<LiveSource>,
        replacesExistingData: null == replacesExistingData
            ? _self.replacesExistingData
            : replacesExistingData // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [SubscriptionCandidate].
extension SubscriptionCandidatePatterns on SubscriptionCandidate {
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
    TResult Function(_SubscriptionCandidate value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SubscriptionCandidate() when $default != null:
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
    TResult Function(_SubscriptionCandidate value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SubscriptionCandidate():
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
    TResult? Function(_SubscriptionCandidate value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SubscriptionCandidate() when $default != null:
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
      String url,
      List<SearchResource> searchSources,
      List<LiveSource> liveSources,
      bool replacesExistingData,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SubscriptionCandidate() when $default != null:
        return $default(
          _that.url,
          _that.searchSources,
          _that.liveSources,
          _that.replacesExistingData,
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
      String url,
      List<SearchResource> searchSources,
      List<LiveSource> liveSources,
      bool replacesExistingData,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SubscriptionCandidate():
        return $default(
          _that.url,
          _that.searchSources,
          _that.liveSources,
          _that.replacesExistingData,
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
      String url,
      List<SearchResource> searchSources,
      List<LiveSource> liveSources,
      bool replacesExistingData,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SubscriptionCandidate() when $default != null:
        return $default(
          _that.url,
          _that.searchSources,
          _that.liveSources,
          _that.replacesExistingData,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _SubscriptionCandidate implements SubscriptionCandidate {
  const _SubscriptionCandidate({
    required this.url,
    required final List<SearchResource> searchSources,
    required final List<LiveSource> liveSources,
    required this.replacesExistingData,
  }) : _searchSources = searchSources,
       _liveSources = liveSources;

  @override
  final String url;
  final List<SearchResource> _searchSources;
  @override
  List<SearchResource> get searchSources {
    if (_searchSources is EqualUnmodifiableListView) return _searchSources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_searchSources);
  }

  final List<LiveSource> _liveSources;
  @override
  List<LiveSource> get liveSources {
    if (_liveSources is EqualUnmodifiableListView) return _liveSources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_liveSources);
  }

  @override
  final bool replacesExistingData;

  /// Create a copy of SubscriptionCandidate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SubscriptionCandidateCopyWith<_SubscriptionCandidate> get copyWith =>
      __$SubscriptionCandidateCopyWithImpl<_SubscriptionCandidate>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SubscriptionCandidate &&
            (identical(other.url, url) || other.url == url) &&
            const DeepCollectionEquality().equals(
              other._searchSources,
              _searchSources,
            ) &&
            const DeepCollectionEquality().equals(
              other._liveSources,
              _liveSources,
            ) &&
            (identical(other.replacesExistingData, replacesExistingData) ||
                other.replacesExistingData == replacesExistingData));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    url,
    const DeepCollectionEquality().hash(_searchSources),
    const DeepCollectionEquality().hash(_liveSources),
    replacesExistingData,
  );

  @override
  String toString() {
    return 'SubscriptionCandidate(url: $url, searchSources: $searchSources, liveSources: $liveSources, replacesExistingData: $replacesExistingData)';
  }
}

/// @nodoc
abstract mixin class _$SubscriptionCandidateCopyWith<$Res>
    implements $SubscriptionCandidateCopyWith<$Res> {
  factory _$SubscriptionCandidateCopyWith(
    _SubscriptionCandidate value,
    $Res Function(_SubscriptionCandidate) _then,
  ) = __$SubscriptionCandidateCopyWithImpl;
  @override
  @useResult
  $Res call({
    String url,
    List<SearchResource> searchSources,
    List<LiveSource> liveSources,
    bool replacesExistingData,
  });
}

/// @nodoc
class __$SubscriptionCandidateCopyWithImpl<$Res>
    implements _$SubscriptionCandidateCopyWith<$Res> {
  __$SubscriptionCandidateCopyWithImpl(this._self, this._then);

  final _SubscriptionCandidate _self;
  final $Res Function(_SubscriptionCandidate) _then;

  /// Create a copy of SubscriptionCandidate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? url = null,
    Object? searchSources = null,
    Object? liveSources = null,
    Object? replacesExistingData = null,
  }) {
    return _then(
      _SubscriptionCandidate(
        url: null == url
            ? _self.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        searchSources: null == searchSources
            ? _self._searchSources
            : searchSources // ignore: cast_nullable_to_non_nullable
                  as List<SearchResource>,
        liveSources: null == liveSources
            ? _self._liveSources
            : liveSources // ignore: cast_nullable_to_non_nullable
                  as List<LiveSource>,
        replacesExistingData: null == replacesExistingData
            ? _self.replacesExistingData
            : replacesExistingData // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}
