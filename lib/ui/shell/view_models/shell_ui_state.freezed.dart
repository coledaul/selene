// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shell_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShellUiState {
  String get query;
  List<String> get suggestions;
  bool get loadingSuggestions;

  /// Create a copy of ShellUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ShellUiStateCopyWith<ShellUiState> get copyWith =>
      _$ShellUiStateCopyWithImpl<ShellUiState>(
        this as ShellUiState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ShellUiState &&
            (identical(other.query, query) || other.query == query) &&
            const DeepCollectionEquality().equals(
              other.suggestions,
              suggestions,
            ) &&
            (identical(other.loadingSuggestions, loadingSuggestions) ||
                other.loadingSuggestions == loadingSuggestions));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    query,
    const DeepCollectionEquality().hash(suggestions),
    loadingSuggestions,
  );

  @override
  String toString() {
    return 'ShellUiState(query: $query, suggestions: $suggestions, loadingSuggestions: $loadingSuggestions)';
  }
}

/// @nodoc
abstract mixin class $ShellUiStateCopyWith<$Res> {
  factory $ShellUiStateCopyWith(
    ShellUiState value,
    $Res Function(ShellUiState) _then,
  ) = _$ShellUiStateCopyWithImpl;
  @useResult
  $Res call({String query, List<String> suggestions, bool loadingSuggestions});
}

/// @nodoc
class _$ShellUiStateCopyWithImpl<$Res> implements $ShellUiStateCopyWith<$Res> {
  _$ShellUiStateCopyWithImpl(this._self, this._then);

  final ShellUiState _self;
  final $Res Function(ShellUiState) _then;

  /// Create a copy of ShellUiState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = null,
    Object? suggestions = null,
    Object? loadingSuggestions = null,
  }) {
    return _then(
      _self.copyWith(
        query: null == query
            ? _self.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
        suggestions: null == suggestions
            ? _self.suggestions
            : suggestions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        loadingSuggestions: null == loadingSuggestions
            ? _self.loadingSuggestions
            : loadingSuggestions // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [ShellUiState].
extension ShellUiStatePatterns on ShellUiState {
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
    TResult Function(_ShellUiState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ShellUiState() when $default != null:
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
    TResult Function(_ShellUiState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShellUiState():
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
    TResult? Function(_ShellUiState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShellUiState() when $default != null:
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
      List<String> suggestions,
      bool loadingSuggestions,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ShellUiState() when $default != null:
        return $default(
          _that.query,
          _that.suggestions,
          _that.loadingSuggestions,
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
      List<String> suggestions,
      bool loadingSuggestions,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShellUiState():
        return $default(
          _that.query,
          _that.suggestions,
          _that.loadingSuggestions,
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
      List<String> suggestions,
      bool loadingSuggestions,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShellUiState() when $default != null:
        return $default(
          _that.query,
          _that.suggestions,
          _that.loadingSuggestions,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ShellUiState implements ShellUiState {
  const _ShellUiState({
    this.query = '',
    final List<String> suggestions = const <String>[],
    this.loadingSuggestions = false,
  }) : _suggestions = suggestions;

  @override
  @JsonKey()
  final String query;
  final List<String> _suggestions;
  @override
  @JsonKey()
  List<String> get suggestions {
    if (_suggestions is EqualUnmodifiableListView) return _suggestions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_suggestions);
  }

  @override
  @JsonKey()
  final bool loadingSuggestions;

  /// Create a copy of ShellUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ShellUiStateCopyWith<_ShellUiState> get copyWith =>
      __$ShellUiStateCopyWithImpl<_ShellUiState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ShellUiState &&
            (identical(other.query, query) || other.query == query) &&
            const DeepCollectionEquality().equals(
              other._suggestions,
              _suggestions,
            ) &&
            (identical(other.loadingSuggestions, loadingSuggestions) ||
                other.loadingSuggestions == loadingSuggestions));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    query,
    const DeepCollectionEquality().hash(_suggestions),
    loadingSuggestions,
  );

  @override
  String toString() {
    return 'ShellUiState(query: $query, suggestions: $suggestions, loadingSuggestions: $loadingSuggestions)';
  }
}

/// @nodoc
abstract mixin class _$ShellUiStateCopyWith<$Res>
    implements $ShellUiStateCopyWith<$Res> {
  factory _$ShellUiStateCopyWith(
    _ShellUiState value,
    $Res Function(_ShellUiState) _then,
  ) = __$ShellUiStateCopyWithImpl;
  @override
  @useResult
  $Res call({String query, List<String> suggestions, bool loadingSuggestions});
}

/// @nodoc
class __$ShellUiStateCopyWithImpl<$Res>
    implements _$ShellUiStateCopyWith<$Res> {
  __$ShellUiStateCopyWithImpl(this._self, this._then);

  final _ShellUiState _self;
  final $Res Function(_ShellUiState) _then;

  /// Create a copy of ShellUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? query = null,
    Object? suggestions = null,
    Object? loadingSuggestions = null,
  }) {
    return _then(
      _ShellUiState(
        query: null == query
            ? _self.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
        suggestions: null == suggestions
            ? _self._suggestions
            : suggestions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        loadingSuggestions: null == loadingSuggestions
            ? _self.loadingSuggestions
            : loadingSuggestions // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}
