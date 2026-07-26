// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppSettings {
  String get doubanDataSource;
  String get doubanImageSource;
  String get m3u8ProxyUrl;
  bool get preferSpeedTest;
  bool get localSearch;
  String get appVersion;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AppSettingsCopyWith<AppSettings> get copyWith =>
      _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppSettings &&
            (identical(other.doubanDataSource, doubanDataSource) ||
                other.doubanDataSource == doubanDataSource) &&
            (identical(other.doubanImageSource, doubanImageSource) ||
                other.doubanImageSource == doubanImageSource) &&
            (identical(other.m3u8ProxyUrl, m3u8ProxyUrl) ||
                other.m3u8ProxyUrl == m3u8ProxyUrl) &&
            (identical(other.preferSpeedTest, preferSpeedTest) ||
                other.preferSpeedTest == preferSpeedTest) &&
            (identical(other.localSearch, localSearch) ||
                other.localSearch == localSearch) &&
            (identical(other.appVersion, appVersion) ||
                other.appVersion == appVersion));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    doubanDataSource,
    doubanImageSource,
    m3u8ProxyUrl,
    preferSpeedTest,
    localSearch,
    appVersion,
  );

  @override
  String toString() {
    return 'AppSettings(doubanDataSource: $doubanDataSource, doubanImageSource: $doubanImageSource, m3u8ProxyUrl: $m3u8ProxyUrl, preferSpeedTest: $preferSpeedTest, localSearch: $localSearch, appVersion: $appVersion)';
  }
}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res> {
  factory $AppSettingsCopyWith(
    AppSettings value,
    $Res Function(AppSettings) _then,
  ) = _$AppSettingsCopyWithImpl;
  @useResult
  $Res call({
    String doubanDataSource,
    String doubanImageSource,
    String m3u8ProxyUrl,
    bool preferSpeedTest,
    bool localSearch,
    String appVersion,
  });
}

/// @nodoc
class _$AppSettingsCopyWithImpl<$Res> implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? doubanDataSource = null,
    Object? doubanImageSource = null,
    Object? m3u8ProxyUrl = null,
    Object? preferSpeedTest = null,
    Object? localSearch = null,
    Object? appVersion = null,
  }) {
    return _then(
      _self.copyWith(
        doubanDataSource: null == doubanDataSource
            ? _self.doubanDataSource
            : doubanDataSource // ignore: cast_nullable_to_non_nullable
                  as String,
        doubanImageSource: null == doubanImageSource
            ? _self.doubanImageSource
            : doubanImageSource // ignore: cast_nullable_to_non_nullable
                  as String,
        m3u8ProxyUrl: null == m3u8ProxyUrl
            ? _self.m3u8ProxyUrl
            : m3u8ProxyUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        preferSpeedTest: null == preferSpeedTest
            ? _self.preferSpeedTest
            : preferSpeedTest // ignore: cast_nullable_to_non_nullable
                  as bool,
        localSearch: null == localSearch
            ? _self.localSearch
            : localSearch // ignore: cast_nullable_to_non_nullable
                  as bool,
        appVersion: null == appVersion
            ? _self.appVersion
            : appVersion // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
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
    TResult Function(_AppSettings value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AppSettings() when $default != null:
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
    TResult Function(_AppSettings value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AppSettings():
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
    TResult? Function(_AppSettings value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AppSettings() when $default != null:
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
      String doubanDataSource,
      String doubanImageSource,
      String m3u8ProxyUrl,
      bool preferSpeedTest,
      bool localSearch,
      String appVersion,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AppSettings() when $default != null:
        return $default(
          _that.doubanDataSource,
          _that.doubanImageSource,
          _that.m3u8ProxyUrl,
          _that.preferSpeedTest,
          _that.localSearch,
          _that.appVersion,
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
      String doubanDataSource,
      String doubanImageSource,
      String m3u8ProxyUrl,
      bool preferSpeedTest,
      bool localSearch,
      String appVersion,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AppSettings():
        return $default(
          _that.doubanDataSource,
          _that.doubanImageSource,
          _that.m3u8ProxyUrl,
          _that.preferSpeedTest,
          _that.localSearch,
          _that.appVersion,
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
      String doubanDataSource,
      String doubanImageSource,
      String m3u8ProxyUrl,
      bool preferSpeedTest,
      bool localSearch,
      String appVersion,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AppSettings() when $default != null:
        return $default(
          _that.doubanDataSource,
          _that.doubanImageSource,
          _that.m3u8ProxyUrl,
          _that.preferSpeedTest,
          _that.localSearch,
          _that.appVersion,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _AppSettings implements AppSettings {
  const _AppSettings({
    this.doubanDataSource = '直连',
    this.doubanImageSource = '直连',
    this.m3u8ProxyUrl = '',
    this.preferSpeedTest = true,
    this.localSearch = false,
    this.appVersion = '',
  });

  @override
  @JsonKey()
  final String doubanDataSource;
  @override
  @JsonKey()
  final String doubanImageSource;
  @override
  @JsonKey()
  final String m3u8ProxyUrl;
  @override
  @JsonKey()
  final bool preferSpeedTest;
  @override
  @JsonKey()
  final bool localSearch;
  @override
  @JsonKey()
  final String appVersion;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AppSettingsCopyWith<_AppSettings> get copyWith =>
      __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AppSettings &&
            (identical(other.doubanDataSource, doubanDataSource) ||
                other.doubanDataSource == doubanDataSource) &&
            (identical(other.doubanImageSource, doubanImageSource) ||
                other.doubanImageSource == doubanImageSource) &&
            (identical(other.m3u8ProxyUrl, m3u8ProxyUrl) ||
                other.m3u8ProxyUrl == m3u8ProxyUrl) &&
            (identical(other.preferSpeedTest, preferSpeedTest) ||
                other.preferSpeedTest == preferSpeedTest) &&
            (identical(other.localSearch, localSearch) ||
                other.localSearch == localSearch) &&
            (identical(other.appVersion, appVersion) ||
                other.appVersion == appVersion));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    doubanDataSource,
    doubanImageSource,
    m3u8ProxyUrl,
    preferSpeedTest,
    localSearch,
    appVersion,
  );

  @override
  String toString() {
    return 'AppSettings(doubanDataSource: $doubanDataSource, doubanImageSource: $doubanImageSource, m3u8ProxyUrl: $m3u8ProxyUrl, preferSpeedTest: $preferSpeedTest, localSearch: $localSearch, appVersion: $appVersion)';
  }
}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res>
    implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(
    _AppSettings value,
    $Res Function(_AppSettings) _then,
  ) = __$AppSettingsCopyWithImpl;
  @override
  @useResult
  $Res call({
    String doubanDataSource,
    String doubanImageSource,
    String m3u8ProxyUrl,
    bool preferSpeedTest,
    bool localSearch,
    String appVersion,
  });
}

/// @nodoc
class __$AppSettingsCopyWithImpl<$Res> implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

  /// Create a copy of AppSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? doubanDataSource = null,
    Object? doubanImageSource = null,
    Object? m3u8ProxyUrl = null,
    Object? preferSpeedTest = null,
    Object? localSearch = null,
    Object? appVersion = null,
  }) {
    return _then(
      _AppSettings(
        doubanDataSource: null == doubanDataSource
            ? _self.doubanDataSource
            : doubanDataSource // ignore: cast_nullable_to_non_nullable
                  as String,
        doubanImageSource: null == doubanImageSource
            ? _self.doubanImageSource
            : doubanImageSource // ignore: cast_nullable_to_non_nullable
                  as String,
        m3u8ProxyUrl: null == m3u8ProxyUrl
            ? _self.m3u8ProxyUrl
            : m3u8ProxyUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        preferSpeedTest: null == preferSpeedTest
            ? _self.preferSpeedTest
            : preferSpeedTest // ignore: cast_nullable_to_non_nullable
                  as bool,
        localSearch: null == localSearch
            ? _self.localSearch
            : localSearch // ignore: cast_nullable_to_non_nullable
                  as bool,
        appVersion: null == appVersion
            ? _self.appVersion
            : appVersion // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}
