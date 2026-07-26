// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'login_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LoginUiState {
  String get serverUrl;
  String get username;
  String get password;
  String get subscriptionUrl;
  bool get rememberLogin;
  bool get localMode;
  bool get passwordVisible;
  String? get authMessage;

  /// Create a copy of LoginUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LoginUiStateCopyWith<LoginUiState> get copyWith =>
      _$LoginUiStateCopyWithImpl<LoginUiState>(
        this as LoginUiState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LoginUiState &&
            (identical(other.serverUrl, serverUrl) ||
                other.serverUrl == serverUrl) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.subscriptionUrl, subscriptionUrl) ||
                other.subscriptionUrl == subscriptionUrl) &&
            (identical(other.rememberLogin, rememberLogin) ||
                other.rememberLogin == rememberLogin) &&
            (identical(other.localMode, localMode) ||
                other.localMode == localMode) &&
            (identical(other.passwordVisible, passwordVisible) ||
                other.passwordVisible == passwordVisible) &&
            (identical(other.authMessage, authMessage) ||
                other.authMessage == authMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    serverUrl,
    username,
    password,
    subscriptionUrl,
    rememberLogin,
    localMode,
    passwordVisible,
    authMessage,
  );

  @override
  String toString() {
    return 'LoginUiState(serverUrl: $serverUrl, username: $username, password: $password, subscriptionUrl: $subscriptionUrl, rememberLogin: $rememberLogin, localMode: $localMode, passwordVisible: $passwordVisible, authMessage: $authMessage)';
  }
}

/// @nodoc
abstract mixin class $LoginUiStateCopyWith<$Res> {
  factory $LoginUiStateCopyWith(
    LoginUiState value,
    $Res Function(LoginUiState) _then,
  ) = _$LoginUiStateCopyWithImpl;
  @useResult
  $Res call({
    String serverUrl,
    String username,
    String password,
    String subscriptionUrl,
    bool rememberLogin,
    bool localMode,
    bool passwordVisible,
    String? authMessage,
  });
}

/// @nodoc
class _$LoginUiStateCopyWithImpl<$Res> implements $LoginUiStateCopyWith<$Res> {
  _$LoginUiStateCopyWithImpl(this._self, this._then);

  final LoginUiState _self;
  final $Res Function(LoginUiState) _then;

  /// Create a copy of LoginUiState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? serverUrl = null,
    Object? username = null,
    Object? password = null,
    Object? subscriptionUrl = null,
    Object? rememberLogin = null,
    Object? localMode = null,
    Object? passwordVisible = null,
    Object? authMessage = freezed,
  }) {
    return _then(
      _self.copyWith(
        serverUrl: null == serverUrl
            ? _self.serverUrl
            : serverUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        username: null == username
            ? _self.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
        password: null == password
            ? _self.password
            : password // ignore: cast_nullable_to_non_nullable
                  as String,
        subscriptionUrl: null == subscriptionUrl
            ? _self.subscriptionUrl
            : subscriptionUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        rememberLogin: null == rememberLogin
            ? _self.rememberLogin
            : rememberLogin // ignore: cast_nullable_to_non_nullable
                  as bool,
        localMode: null == localMode
            ? _self.localMode
            : localMode // ignore: cast_nullable_to_non_nullable
                  as bool,
        passwordVisible: null == passwordVisible
            ? _self.passwordVisible
            : passwordVisible // ignore: cast_nullable_to_non_nullable
                  as bool,
        authMessage: freezed == authMessage
            ? _self.authMessage
            : authMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [LoginUiState].
extension LoginUiStatePatterns on LoginUiState {
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
    TResult Function(_LoginUiState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LoginUiState() when $default != null:
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
    TResult Function(_LoginUiState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LoginUiState():
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
    TResult? Function(_LoginUiState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LoginUiState() when $default != null:
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
      String serverUrl,
      String username,
      String password,
      String subscriptionUrl,
      bool rememberLogin,
      bool localMode,
      bool passwordVisible,
      String? authMessage,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LoginUiState() when $default != null:
        return $default(
          _that.serverUrl,
          _that.username,
          _that.password,
          _that.subscriptionUrl,
          _that.rememberLogin,
          _that.localMode,
          _that.passwordVisible,
          _that.authMessage,
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
      String serverUrl,
      String username,
      String password,
      String subscriptionUrl,
      bool rememberLogin,
      bool localMode,
      bool passwordVisible,
      String? authMessage,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LoginUiState():
        return $default(
          _that.serverUrl,
          _that.username,
          _that.password,
          _that.subscriptionUrl,
          _that.rememberLogin,
          _that.localMode,
          _that.passwordVisible,
          _that.authMessage,
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
      String serverUrl,
      String username,
      String password,
      String subscriptionUrl,
      bool rememberLogin,
      bool localMode,
      bool passwordVisible,
      String? authMessage,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LoginUiState() when $default != null:
        return $default(
          _that.serverUrl,
          _that.username,
          _that.password,
          _that.subscriptionUrl,
          _that.rememberLogin,
          _that.localMode,
          _that.passwordVisible,
          _that.authMessage,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _LoginUiState extends LoginUiState {
  const _LoginUiState({
    this.serverUrl = '',
    this.username = '',
    this.password = '',
    this.subscriptionUrl = '',
    this.rememberLogin = false,
    this.localMode = false,
    this.passwordVisible = false,
    this.authMessage,
  }) : super._();

  @override
  @JsonKey()
  final String serverUrl;
  @override
  @JsonKey()
  final String username;
  @override
  @JsonKey()
  final String password;
  @override
  @JsonKey()
  final String subscriptionUrl;
  @override
  @JsonKey()
  final bool rememberLogin;
  @override
  @JsonKey()
  final bool localMode;
  @override
  @JsonKey()
  final bool passwordVisible;
  @override
  final String? authMessage;

  /// Create a copy of LoginUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LoginUiStateCopyWith<_LoginUiState> get copyWith =>
      __$LoginUiStateCopyWithImpl<_LoginUiState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LoginUiState &&
            (identical(other.serverUrl, serverUrl) ||
                other.serverUrl == serverUrl) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.subscriptionUrl, subscriptionUrl) ||
                other.subscriptionUrl == subscriptionUrl) &&
            (identical(other.rememberLogin, rememberLogin) ||
                other.rememberLogin == rememberLogin) &&
            (identical(other.localMode, localMode) ||
                other.localMode == localMode) &&
            (identical(other.passwordVisible, passwordVisible) ||
                other.passwordVisible == passwordVisible) &&
            (identical(other.authMessage, authMessage) ||
                other.authMessage == authMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    serverUrl,
    username,
    password,
    subscriptionUrl,
    rememberLogin,
    localMode,
    passwordVisible,
    authMessage,
  );

  @override
  String toString() {
    return 'LoginUiState(serverUrl: $serverUrl, username: $username, password: $password, subscriptionUrl: $subscriptionUrl, rememberLogin: $rememberLogin, localMode: $localMode, passwordVisible: $passwordVisible, authMessage: $authMessage)';
  }
}

/// @nodoc
abstract mixin class _$LoginUiStateCopyWith<$Res>
    implements $LoginUiStateCopyWith<$Res> {
  factory _$LoginUiStateCopyWith(
    _LoginUiState value,
    $Res Function(_LoginUiState) _then,
  ) = __$LoginUiStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    String serverUrl,
    String username,
    String password,
    String subscriptionUrl,
    bool rememberLogin,
    bool localMode,
    bool passwordVisible,
    String? authMessage,
  });
}

/// @nodoc
class __$LoginUiStateCopyWithImpl<$Res>
    implements _$LoginUiStateCopyWith<$Res> {
  __$LoginUiStateCopyWithImpl(this._self, this._then);

  final _LoginUiState _self;
  final $Res Function(_LoginUiState) _then;

  /// Create a copy of LoginUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? serverUrl = null,
    Object? username = null,
    Object? password = null,
    Object? subscriptionUrl = null,
    Object? rememberLogin = null,
    Object? localMode = null,
    Object? passwordVisible = null,
    Object? authMessage = freezed,
  }) {
    return _then(
      _LoginUiState(
        serverUrl: null == serverUrl
            ? _self.serverUrl
            : serverUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        username: null == username
            ? _self.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
        password: null == password
            ? _self.password
            : password // ignore: cast_nullable_to_non_nullable
                  as String,
        subscriptionUrl: null == subscriptionUrl
            ? _self.subscriptionUrl
            : subscriptionUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        rememberLogin: null == rememberLogin
            ? _self.rememberLogin
            : rememberLogin // ignore: cast_nullable_to_non_nullable
                  as bool,
        localMode: null == localMode
            ? _self.localMode
            : localMode // ignore: cast_nullable_to_non_nullable
                  as bool,
        passwordVisible: null == passwordVisible
            ? _self.passwordVisible
            : passwordVisible // ignore: cast_nullable_to_non_nullable
                  as bool,
        authMessage: freezed == authMessage
            ? _self.authMessage
            : authMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}
