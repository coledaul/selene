// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_version.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppVersionInfo {
  String get currentVersion;
  String get latestVersion;
  String get releaseNotes;
  Uri get releaseUri;

  /// Create a copy of AppVersionInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AppVersionInfoCopyWith<AppVersionInfo> get copyWith =>
      _$AppVersionInfoCopyWithImpl<AppVersionInfo>(
        this as AppVersionInfo,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppVersionInfo &&
            (identical(other.currentVersion, currentVersion) ||
                other.currentVersion == currentVersion) &&
            (identical(other.latestVersion, latestVersion) ||
                other.latestVersion == latestVersion) &&
            (identical(other.releaseNotes, releaseNotes) ||
                other.releaseNotes == releaseNotes) &&
            (identical(other.releaseUri, releaseUri) ||
                other.releaseUri == releaseUri));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    currentVersion,
    latestVersion,
    releaseNotes,
    releaseUri,
  );

  @override
  String toString() {
    return 'AppVersionInfo(currentVersion: $currentVersion, latestVersion: $latestVersion, releaseNotes: $releaseNotes, releaseUri: $releaseUri)';
  }
}

/// @nodoc
abstract mixin class $AppVersionInfoCopyWith<$Res> {
  factory $AppVersionInfoCopyWith(
    AppVersionInfo value,
    $Res Function(AppVersionInfo) _then,
  ) = _$AppVersionInfoCopyWithImpl;
  @useResult
  $Res call({
    String currentVersion,
    String latestVersion,
    String releaseNotes,
    Uri releaseUri,
  });
}

/// @nodoc
class _$AppVersionInfoCopyWithImpl<$Res>
    implements $AppVersionInfoCopyWith<$Res> {
  _$AppVersionInfoCopyWithImpl(this._self, this._then);

  final AppVersionInfo _self;
  final $Res Function(AppVersionInfo) _then;

  /// Create a copy of AppVersionInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentVersion = null,
    Object? latestVersion = null,
    Object? releaseNotes = null,
    Object? releaseUri = null,
  }) {
    return _then(
      _self.copyWith(
        currentVersion: null == currentVersion
            ? _self.currentVersion
            : currentVersion // ignore: cast_nullable_to_non_nullable
                  as String,
        latestVersion: null == latestVersion
            ? _self.latestVersion
            : latestVersion // ignore: cast_nullable_to_non_nullable
                  as String,
        releaseNotes: null == releaseNotes
            ? _self.releaseNotes
            : releaseNotes // ignore: cast_nullable_to_non_nullable
                  as String,
        releaseUri: null == releaseUri
            ? _self.releaseUri
            : releaseUri // ignore: cast_nullable_to_non_nullable
                  as Uri,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [AppVersionInfo].
extension AppVersionInfoPatterns on AppVersionInfo {
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
    TResult Function(_AppVersionInfo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AppVersionInfo() when $default != null:
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
    TResult Function(_AppVersionInfo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AppVersionInfo():
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
    TResult? Function(_AppVersionInfo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AppVersionInfo() when $default != null:
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
      String currentVersion,
      String latestVersion,
      String releaseNotes,
      Uri releaseUri,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AppVersionInfo() when $default != null:
        return $default(
          _that.currentVersion,
          _that.latestVersion,
          _that.releaseNotes,
          _that.releaseUri,
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
      String currentVersion,
      String latestVersion,
      String releaseNotes,
      Uri releaseUri,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AppVersionInfo():
        return $default(
          _that.currentVersion,
          _that.latestVersion,
          _that.releaseNotes,
          _that.releaseUri,
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
      String currentVersion,
      String latestVersion,
      String releaseNotes,
      Uri releaseUri,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AppVersionInfo() when $default != null:
        return $default(
          _that.currentVersion,
          _that.latestVersion,
          _that.releaseNotes,
          _that.releaseUri,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _AppVersionInfo implements AppVersionInfo {
  const _AppVersionInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.releaseUri,
  });

  @override
  final String currentVersion;
  @override
  final String latestVersion;
  @override
  final String releaseNotes;
  @override
  final Uri releaseUri;

  /// Create a copy of AppVersionInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AppVersionInfoCopyWith<_AppVersionInfo> get copyWith =>
      __$AppVersionInfoCopyWithImpl<_AppVersionInfo>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AppVersionInfo &&
            (identical(other.currentVersion, currentVersion) ||
                other.currentVersion == currentVersion) &&
            (identical(other.latestVersion, latestVersion) ||
                other.latestVersion == latestVersion) &&
            (identical(other.releaseNotes, releaseNotes) ||
                other.releaseNotes == releaseNotes) &&
            (identical(other.releaseUri, releaseUri) ||
                other.releaseUri == releaseUri));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    currentVersion,
    latestVersion,
    releaseNotes,
    releaseUri,
  );

  @override
  String toString() {
    return 'AppVersionInfo(currentVersion: $currentVersion, latestVersion: $latestVersion, releaseNotes: $releaseNotes, releaseUri: $releaseUri)';
  }
}

/// @nodoc
abstract mixin class _$AppVersionInfoCopyWith<$Res>
    implements $AppVersionInfoCopyWith<$Res> {
  factory _$AppVersionInfoCopyWith(
    _AppVersionInfo value,
    $Res Function(_AppVersionInfo) _then,
  ) = __$AppVersionInfoCopyWithImpl;
  @override
  @useResult
  $Res call({
    String currentVersion,
    String latestVersion,
    String releaseNotes,
    Uri releaseUri,
  });
}

/// @nodoc
class __$AppVersionInfoCopyWithImpl<$Res>
    implements _$AppVersionInfoCopyWith<$Res> {
  __$AppVersionInfoCopyWithImpl(this._self, this._then);

  final _AppVersionInfo _self;
  final $Res Function(_AppVersionInfo) _then;

  /// Create a copy of AppVersionInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? currentVersion = null,
    Object? latestVersion = null,
    Object? releaseNotes = null,
    Object? releaseUri = null,
  }) {
    return _then(
      _AppVersionInfo(
        currentVersion: null == currentVersion
            ? _self.currentVersion
            : currentVersion // ignore: cast_nullable_to_non_nullable
                  as String,
        latestVersion: null == latestVersion
            ? _self.latestVersion
            : latestVersion // ignore: cast_nullable_to_non_nullable
                  as String,
        releaseNotes: null == releaseNotes
            ? _self.releaseNotes
            : releaseNotes // ignore: cast_nullable_to_non_nullable
                  as String,
        releaseUri: null == releaseUri
            ? _self.releaseUri
            : releaseUri // ignore: cast_nullable_to_non_nullable
                  as Uri,
      ),
    );
  }
}
