// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlayerUiState {
  SearchResult? get currentDetail;
  String get searchTitle;
  String get videoTitle;
  String get videoDescription;
  String get videoYear;
  String get videoCover;
  int get doubanId;
  DoubanMovieDetails? get doubanDetails;
  String get currentSource;
  String get currentId;
  bool get preferSource;
  int get totalEpisodes;
  int get currentEpisodeIndex;
  bool get favorite;
  bool get loading;
  double get loadingProgress;
  String get loadingMessage;
  String get loadingEmoji;
  String? get errorMessage;
  String? get warningMessage;
  int get resumeEpisodeIndex;
  int get resumePlayTime;
  List<SearchResult> get sources;
  Map<String, PlayerSourceSpeed> get sourceSpeeds;

  /// Create a copy of PlayerUiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlayerUiStateCopyWith<PlayerUiState> get copyWith =>
      _$PlayerUiStateCopyWithImpl<PlayerUiState>(
        this as PlayerUiState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlayerUiState &&
            (identical(other.currentDetail, currentDetail) ||
                other.currentDetail == currentDetail) &&
            (identical(other.searchTitle, searchTitle) ||
                other.searchTitle == searchTitle) &&
            (identical(other.videoTitle, videoTitle) ||
                other.videoTitle == videoTitle) &&
            (identical(other.videoDescription, videoDescription) ||
                other.videoDescription == videoDescription) &&
            (identical(other.videoYear, videoYear) ||
                other.videoYear == videoYear) &&
            (identical(other.videoCover, videoCover) ||
                other.videoCover == videoCover) &&
            (identical(other.doubanId, doubanId) ||
                other.doubanId == doubanId) &&
            (identical(other.doubanDetails, doubanDetails) ||
                other.doubanDetails == doubanDetails) &&
            (identical(other.currentSource, currentSource) ||
                other.currentSource == currentSource) &&
            (identical(other.currentId, currentId) ||
                other.currentId == currentId) &&
            (identical(other.preferSource, preferSource) ||
                other.preferSource == preferSource) &&
            (identical(other.totalEpisodes, totalEpisodes) ||
                other.totalEpisodes == totalEpisodes) &&
            (identical(other.currentEpisodeIndex, currentEpisodeIndex) ||
                other.currentEpisodeIndex == currentEpisodeIndex) &&
            (identical(other.favorite, favorite) ||
                other.favorite == favorite) &&
            (identical(other.loading, loading) || other.loading == loading) &&
            (identical(other.loadingProgress, loadingProgress) ||
                other.loadingProgress == loadingProgress) &&
            (identical(other.loadingMessage, loadingMessage) ||
                other.loadingMessage == loadingMessage) &&
            (identical(other.loadingEmoji, loadingEmoji) ||
                other.loadingEmoji == loadingEmoji) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.warningMessage, warningMessage) ||
                other.warningMessage == warningMessage) &&
            (identical(other.resumeEpisodeIndex, resumeEpisodeIndex) ||
                other.resumeEpisodeIndex == resumeEpisodeIndex) &&
            (identical(other.resumePlayTime, resumePlayTime) ||
                other.resumePlayTime == resumePlayTime) &&
            const DeepCollectionEquality().equals(other.sources, sources) &&
            const DeepCollectionEquality().equals(
              other.sourceSpeeds,
              sourceSpeeds,
            ));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    currentDetail,
    searchTitle,
    videoTitle,
    videoDescription,
    videoYear,
    videoCover,
    doubanId,
    doubanDetails,
    currentSource,
    currentId,
    preferSource,
    totalEpisodes,
    currentEpisodeIndex,
    favorite,
    loading,
    loadingProgress,
    loadingMessage,
    loadingEmoji,
    errorMessage,
    warningMessage,
    resumeEpisodeIndex,
    resumePlayTime,
    const DeepCollectionEquality().hash(sources),
    const DeepCollectionEquality().hash(sourceSpeeds),
  ]);

  @override
  String toString() {
    return 'PlayerUiState(currentDetail: $currentDetail, searchTitle: $searchTitle, videoTitle: $videoTitle, videoDescription: $videoDescription, videoYear: $videoYear, videoCover: $videoCover, doubanId: $doubanId, doubanDetails: $doubanDetails, currentSource: $currentSource, currentId: $currentId, preferSource: $preferSource, totalEpisodes: $totalEpisodes, currentEpisodeIndex: $currentEpisodeIndex, favorite: $favorite, loading: $loading, loadingProgress: $loadingProgress, loadingMessage: $loadingMessage, loadingEmoji: $loadingEmoji, errorMessage: $errorMessage, warningMessage: $warningMessage, resumeEpisodeIndex: $resumeEpisodeIndex, resumePlayTime: $resumePlayTime, sources: $sources, sourceSpeeds: $sourceSpeeds)';
  }
}

/// @nodoc
abstract mixin class $PlayerUiStateCopyWith<$Res> {
  factory $PlayerUiStateCopyWith(
    PlayerUiState value,
    $Res Function(PlayerUiState) _then,
  ) = _$PlayerUiStateCopyWithImpl;
  @useResult
  $Res call({
    SearchResult? currentDetail,
    String searchTitle,
    String videoTitle,
    String videoDescription,
    String videoYear,
    String videoCover,
    int doubanId,
    DoubanMovieDetails? doubanDetails,
    String currentSource,
    String currentId,
    bool preferSource,
    int totalEpisodes,
    int currentEpisodeIndex,
    bool favorite,
    bool loading,
    double loadingProgress,
    String loadingMessage,
    String loadingEmoji,
    String? errorMessage,
    String? warningMessage,
    int resumeEpisodeIndex,
    int resumePlayTime,
    List<SearchResult> sources,
    Map<String, PlayerSourceSpeed> sourceSpeeds,
  });
}

/// @nodoc
class _$PlayerUiStateCopyWithImpl<$Res>
    implements $PlayerUiStateCopyWith<$Res> {
  _$PlayerUiStateCopyWithImpl(this._self, this._then);

  final PlayerUiState _self;
  final $Res Function(PlayerUiState) _then;

  /// Create a copy of PlayerUiState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentDetail = freezed,
    Object? searchTitle = null,
    Object? videoTitle = null,
    Object? videoDescription = null,
    Object? videoYear = null,
    Object? videoCover = null,
    Object? doubanId = null,
    Object? doubanDetails = freezed,
    Object? currentSource = null,
    Object? currentId = null,
    Object? preferSource = null,
    Object? totalEpisodes = null,
    Object? currentEpisodeIndex = null,
    Object? favorite = null,
    Object? loading = null,
    Object? loadingProgress = null,
    Object? loadingMessage = null,
    Object? loadingEmoji = null,
    Object? errorMessage = freezed,
    Object? warningMessage = freezed,
    Object? resumeEpisodeIndex = null,
    Object? resumePlayTime = null,
    Object? sources = null,
    Object? sourceSpeeds = null,
  }) {
    return _then(
      _self.copyWith(
        currentDetail: freezed == currentDetail
            ? _self.currentDetail
            : currentDetail // ignore: cast_nullable_to_non_nullable
                  as SearchResult?,
        searchTitle: null == searchTitle
            ? _self.searchTitle
            : searchTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        videoTitle: null == videoTitle
            ? _self.videoTitle
            : videoTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        videoDescription: null == videoDescription
            ? _self.videoDescription
            : videoDescription // ignore: cast_nullable_to_non_nullable
                  as String,
        videoYear: null == videoYear
            ? _self.videoYear
            : videoYear // ignore: cast_nullable_to_non_nullable
                  as String,
        videoCover: null == videoCover
            ? _self.videoCover
            : videoCover // ignore: cast_nullable_to_non_nullable
                  as String,
        doubanId: null == doubanId
            ? _self.doubanId
            : doubanId // ignore: cast_nullable_to_non_nullable
                  as int,
        doubanDetails: freezed == doubanDetails
            ? _self.doubanDetails
            : doubanDetails // ignore: cast_nullable_to_non_nullable
                  as DoubanMovieDetails?,
        currentSource: null == currentSource
            ? _self.currentSource
            : currentSource // ignore: cast_nullable_to_non_nullable
                  as String,
        currentId: null == currentId
            ? _self.currentId
            : currentId // ignore: cast_nullable_to_non_nullable
                  as String,
        preferSource: null == preferSource
            ? _self.preferSource
            : preferSource // ignore: cast_nullable_to_non_nullable
                  as bool,
        totalEpisodes: null == totalEpisodes
            ? _self.totalEpisodes
            : totalEpisodes // ignore: cast_nullable_to_non_nullable
                  as int,
        currentEpisodeIndex: null == currentEpisodeIndex
            ? _self.currentEpisodeIndex
            : currentEpisodeIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        favorite: null == favorite
            ? _self.favorite
            : favorite // ignore: cast_nullable_to_non_nullable
                  as bool,
        loading: null == loading
            ? _self.loading
            : loading // ignore: cast_nullable_to_non_nullable
                  as bool,
        loadingProgress: null == loadingProgress
            ? _self.loadingProgress
            : loadingProgress // ignore: cast_nullable_to_non_nullable
                  as double,
        loadingMessage: null == loadingMessage
            ? _self.loadingMessage
            : loadingMessage // ignore: cast_nullable_to_non_nullable
                  as String,
        loadingEmoji: null == loadingEmoji
            ? _self.loadingEmoji
            : loadingEmoji // ignore: cast_nullable_to_non_nullable
                  as String,
        errorMessage: freezed == errorMessage
            ? _self.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        warningMessage: freezed == warningMessage
            ? _self.warningMessage
            : warningMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        resumeEpisodeIndex: null == resumeEpisodeIndex
            ? _self.resumeEpisodeIndex
            : resumeEpisodeIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        resumePlayTime: null == resumePlayTime
            ? _self.resumePlayTime
            : resumePlayTime // ignore: cast_nullable_to_non_nullable
                  as int,
        sources: null == sources
            ? _self.sources
            : sources // ignore: cast_nullable_to_non_nullable
                  as List<SearchResult>,
        sourceSpeeds: null == sourceSpeeds
            ? _self.sourceSpeeds
            : sourceSpeeds // ignore: cast_nullable_to_non_nullable
                  as Map<String, PlayerSourceSpeed>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [PlayerUiState].
extension PlayerUiStatePatterns on PlayerUiState {
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
    TResult Function(_PlayerUiState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlayerUiState() when $default != null:
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
    TResult Function(_PlayerUiState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlayerUiState():
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
    TResult? Function(_PlayerUiState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlayerUiState() when $default != null:
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
      SearchResult? currentDetail,
      String searchTitle,
      String videoTitle,
      String videoDescription,
      String videoYear,
      String videoCover,
      int doubanId,
      DoubanMovieDetails? doubanDetails,
      String currentSource,
      String currentId,
      bool preferSource,
      int totalEpisodes,
      int currentEpisodeIndex,
      bool favorite,
      bool loading,
      double loadingProgress,
      String loadingMessage,
      String loadingEmoji,
      String? errorMessage,
      String? warningMessage,
      int resumeEpisodeIndex,
      int resumePlayTime,
      List<SearchResult> sources,
      Map<String, PlayerSourceSpeed> sourceSpeeds,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlayerUiState() when $default != null:
        return $default(
          _that.currentDetail,
          _that.searchTitle,
          _that.videoTitle,
          _that.videoDescription,
          _that.videoYear,
          _that.videoCover,
          _that.doubanId,
          _that.doubanDetails,
          _that.currentSource,
          _that.currentId,
          _that.preferSource,
          _that.totalEpisodes,
          _that.currentEpisodeIndex,
          _that.favorite,
          _that.loading,
          _that.loadingProgress,
          _that.loadingMessage,
          _that.loadingEmoji,
          _that.errorMessage,
          _that.warningMessage,
          _that.resumeEpisodeIndex,
          _that.resumePlayTime,
          _that.sources,
          _that.sourceSpeeds,
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
      SearchResult? currentDetail,
      String searchTitle,
      String videoTitle,
      String videoDescription,
      String videoYear,
      String videoCover,
      int doubanId,
      DoubanMovieDetails? doubanDetails,
      String currentSource,
      String currentId,
      bool preferSource,
      int totalEpisodes,
      int currentEpisodeIndex,
      bool favorite,
      bool loading,
      double loadingProgress,
      String loadingMessage,
      String loadingEmoji,
      String? errorMessage,
      String? warningMessage,
      int resumeEpisodeIndex,
      int resumePlayTime,
      List<SearchResult> sources,
      Map<String, PlayerSourceSpeed> sourceSpeeds,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlayerUiState():
        return $default(
          _that.currentDetail,
          _that.searchTitle,
          _that.videoTitle,
          _that.videoDescription,
          _that.videoYear,
          _that.videoCover,
          _that.doubanId,
          _that.doubanDetails,
          _that.currentSource,
          _that.currentId,
          _that.preferSource,
          _that.totalEpisodes,
          _that.currentEpisodeIndex,
          _that.favorite,
          _that.loading,
          _that.loadingProgress,
          _that.loadingMessage,
          _that.loadingEmoji,
          _that.errorMessage,
          _that.warningMessage,
          _that.resumeEpisodeIndex,
          _that.resumePlayTime,
          _that.sources,
          _that.sourceSpeeds,
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
      SearchResult? currentDetail,
      String searchTitle,
      String videoTitle,
      String videoDescription,
      String videoYear,
      String videoCover,
      int doubanId,
      DoubanMovieDetails? doubanDetails,
      String currentSource,
      String currentId,
      bool preferSource,
      int totalEpisodes,
      int currentEpisodeIndex,
      bool favorite,
      bool loading,
      double loadingProgress,
      String loadingMessage,
      String loadingEmoji,
      String? errorMessage,
      String? warningMessage,
      int resumeEpisodeIndex,
      int resumePlayTime,
      List<SearchResult> sources,
      Map<String, PlayerSourceSpeed> sourceSpeeds,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlayerUiState() when $default != null:
        return $default(
          _that.currentDetail,
          _that.searchTitle,
          _that.videoTitle,
          _that.videoDescription,
          _that.videoYear,
          _that.videoCover,
          _that.doubanId,
          _that.doubanDetails,
          _that.currentSource,
          _that.currentId,
          _that.preferSource,
          _that.totalEpisodes,
          _that.currentEpisodeIndex,
          _that.favorite,
          _that.loading,
          _that.loadingProgress,
          _that.loadingMessage,
          _that.loadingEmoji,
          _that.errorMessage,
          _that.warningMessage,
          _that.resumeEpisodeIndex,
          _that.resumePlayTime,
          _that.sources,
          _that.sourceSpeeds,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _PlayerUiState implements PlayerUiState {
  const _PlayerUiState({
    this.currentDetail,
    this.searchTitle = '',
    this.videoTitle = '',
    this.videoDescription = '',
    this.videoYear = '',
    this.videoCover = '',
    this.doubanId = 0,
    this.doubanDetails,
    this.currentSource = '',
    this.currentId = '',
    this.preferSource = false,
    this.totalEpisodes = 0,
    this.currentEpisodeIndex = 0,
    this.favorite = false,
    this.loading = false,
    this.loadingProgress = 0,
    this.loadingMessage = '',
    this.loadingEmoji = '',
    this.errorMessage,
    this.warningMessage,
    this.resumeEpisodeIndex = 0,
    this.resumePlayTime = 0,
    final List<SearchResult> sources = const <SearchResult>[],
    final Map<String, PlayerSourceSpeed> sourceSpeeds =
        const <String, PlayerSourceSpeed>{},
  }) : _sources = sources,
       _sourceSpeeds = sourceSpeeds;

  @override
  final SearchResult? currentDetail;
  @override
  @JsonKey()
  final String searchTitle;
  @override
  @JsonKey()
  final String videoTitle;
  @override
  @JsonKey()
  final String videoDescription;
  @override
  @JsonKey()
  final String videoYear;
  @override
  @JsonKey()
  final String videoCover;
  @override
  @JsonKey()
  final int doubanId;
  @override
  final DoubanMovieDetails? doubanDetails;
  @override
  @JsonKey()
  final String currentSource;
  @override
  @JsonKey()
  final String currentId;
  @override
  @JsonKey()
  final bool preferSource;
  @override
  @JsonKey()
  final int totalEpisodes;
  @override
  @JsonKey()
  final int currentEpisodeIndex;
  @override
  @JsonKey()
  final bool favorite;
  @override
  @JsonKey()
  final bool loading;
  @override
  @JsonKey()
  final double loadingProgress;
  @override
  @JsonKey()
  final String loadingMessage;
  @override
  @JsonKey()
  final String loadingEmoji;
  @override
  final String? errorMessage;
  @override
  final String? warningMessage;
  @override
  @JsonKey()
  final int resumeEpisodeIndex;
  @override
  @JsonKey()
  final int resumePlayTime;
  final List<SearchResult> _sources;
  @override
  @JsonKey()
  List<SearchResult> get sources {
    if (_sources is EqualUnmodifiableListView) return _sources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sources);
  }

  final Map<String, PlayerSourceSpeed> _sourceSpeeds;
  @override
  @JsonKey()
  Map<String, PlayerSourceSpeed> get sourceSpeeds {
    if (_sourceSpeeds is EqualUnmodifiableMapView) return _sourceSpeeds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_sourceSpeeds);
  }

  /// Create a copy of PlayerUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PlayerUiStateCopyWith<_PlayerUiState> get copyWith =>
      __$PlayerUiStateCopyWithImpl<_PlayerUiState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PlayerUiState &&
            (identical(other.currentDetail, currentDetail) ||
                other.currentDetail == currentDetail) &&
            (identical(other.searchTitle, searchTitle) ||
                other.searchTitle == searchTitle) &&
            (identical(other.videoTitle, videoTitle) ||
                other.videoTitle == videoTitle) &&
            (identical(other.videoDescription, videoDescription) ||
                other.videoDescription == videoDescription) &&
            (identical(other.videoYear, videoYear) ||
                other.videoYear == videoYear) &&
            (identical(other.videoCover, videoCover) ||
                other.videoCover == videoCover) &&
            (identical(other.doubanId, doubanId) ||
                other.doubanId == doubanId) &&
            (identical(other.doubanDetails, doubanDetails) ||
                other.doubanDetails == doubanDetails) &&
            (identical(other.currentSource, currentSource) ||
                other.currentSource == currentSource) &&
            (identical(other.currentId, currentId) ||
                other.currentId == currentId) &&
            (identical(other.preferSource, preferSource) ||
                other.preferSource == preferSource) &&
            (identical(other.totalEpisodes, totalEpisodes) ||
                other.totalEpisodes == totalEpisodes) &&
            (identical(other.currentEpisodeIndex, currentEpisodeIndex) ||
                other.currentEpisodeIndex == currentEpisodeIndex) &&
            (identical(other.favorite, favorite) ||
                other.favorite == favorite) &&
            (identical(other.loading, loading) || other.loading == loading) &&
            (identical(other.loadingProgress, loadingProgress) ||
                other.loadingProgress == loadingProgress) &&
            (identical(other.loadingMessage, loadingMessage) ||
                other.loadingMessage == loadingMessage) &&
            (identical(other.loadingEmoji, loadingEmoji) ||
                other.loadingEmoji == loadingEmoji) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.warningMessage, warningMessage) ||
                other.warningMessage == warningMessage) &&
            (identical(other.resumeEpisodeIndex, resumeEpisodeIndex) ||
                other.resumeEpisodeIndex == resumeEpisodeIndex) &&
            (identical(other.resumePlayTime, resumePlayTime) ||
                other.resumePlayTime == resumePlayTime) &&
            const DeepCollectionEquality().equals(other._sources, _sources) &&
            const DeepCollectionEquality().equals(
              other._sourceSpeeds,
              _sourceSpeeds,
            ));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    currentDetail,
    searchTitle,
    videoTitle,
    videoDescription,
    videoYear,
    videoCover,
    doubanId,
    doubanDetails,
    currentSource,
    currentId,
    preferSource,
    totalEpisodes,
    currentEpisodeIndex,
    favorite,
    loading,
    loadingProgress,
    loadingMessage,
    loadingEmoji,
    errorMessage,
    warningMessage,
    resumeEpisodeIndex,
    resumePlayTime,
    const DeepCollectionEquality().hash(_sources),
    const DeepCollectionEquality().hash(_sourceSpeeds),
  ]);

  @override
  String toString() {
    return 'PlayerUiState(currentDetail: $currentDetail, searchTitle: $searchTitle, videoTitle: $videoTitle, videoDescription: $videoDescription, videoYear: $videoYear, videoCover: $videoCover, doubanId: $doubanId, doubanDetails: $doubanDetails, currentSource: $currentSource, currentId: $currentId, preferSource: $preferSource, totalEpisodes: $totalEpisodes, currentEpisodeIndex: $currentEpisodeIndex, favorite: $favorite, loading: $loading, loadingProgress: $loadingProgress, loadingMessage: $loadingMessage, loadingEmoji: $loadingEmoji, errorMessage: $errorMessage, warningMessage: $warningMessage, resumeEpisodeIndex: $resumeEpisodeIndex, resumePlayTime: $resumePlayTime, sources: $sources, sourceSpeeds: $sourceSpeeds)';
  }
}

/// @nodoc
abstract mixin class _$PlayerUiStateCopyWith<$Res>
    implements $PlayerUiStateCopyWith<$Res> {
  factory _$PlayerUiStateCopyWith(
    _PlayerUiState value,
    $Res Function(_PlayerUiState) _then,
  ) = __$PlayerUiStateCopyWithImpl;
  @override
  @useResult
  $Res call({
    SearchResult? currentDetail,
    String searchTitle,
    String videoTitle,
    String videoDescription,
    String videoYear,
    String videoCover,
    int doubanId,
    DoubanMovieDetails? doubanDetails,
    String currentSource,
    String currentId,
    bool preferSource,
    int totalEpisodes,
    int currentEpisodeIndex,
    bool favorite,
    bool loading,
    double loadingProgress,
    String loadingMessage,
    String loadingEmoji,
    String? errorMessage,
    String? warningMessage,
    int resumeEpisodeIndex,
    int resumePlayTime,
    List<SearchResult> sources,
    Map<String, PlayerSourceSpeed> sourceSpeeds,
  });
}

/// @nodoc
class __$PlayerUiStateCopyWithImpl<$Res>
    implements _$PlayerUiStateCopyWith<$Res> {
  __$PlayerUiStateCopyWithImpl(this._self, this._then);

  final _PlayerUiState _self;
  final $Res Function(_PlayerUiState) _then;

  /// Create a copy of PlayerUiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? currentDetail = freezed,
    Object? searchTitle = null,
    Object? videoTitle = null,
    Object? videoDescription = null,
    Object? videoYear = null,
    Object? videoCover = null,
    Object? doubanId = null,
    Object? doubanDetails = freezed,
    Object? currentSource = null,
    Object? currentId = null,
    Object? preferSource = null,
    Object? totalEpisodes = null,
    Object? currentEpisodeIndex = null,
    Object? favorite = null,
    Object? loading = null,
    Object? loadingProgress = null,
    Object? loadingMessage = null,
    Object? loadingEmoji = null,
    Object? errorMessage = freezed,
    Object? warningMessage = freezed,
    Object? resumeEpisodeIndex = null,
    Object? resumePlayTime = null,
    Object? sources = null,
    Object? sourceSpeeds = null,
  }) {
    return _then(
      _PlayerUiState(
        currentDetail: freezed == currentDetail
            ? _self.currentDetail
            : currentDetail // ignore: cast_nullable_to_non_nullable
                  as SearchResult?,
        searchTitle: null == searchTitle
            ? _self.searchTitle
            : searchTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        videoTitle: null == videoTitle
            ? _self.videoTitle
            : videoTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        videoDescription: null == videoDescription
            ? _self.videoDescription
            : videoDescription // ignore: cast_nullable_to_non_nullable
                  as String,
        videoYear: null == videoYear
            ? _self.videoYear
            : videoYear // ignore: cast_nullable_to_non_nullable
                  as String,
        videoCover: null == videoCover
            ? _self.videoCover
            : videoCover // ignore: cast_nullable_to_non_nullable
                  as String,
        doubanId: null == doubanId
            ? _self.doubanId
            : doubanId // ignore: cast_nullable_to_non_nullable
                  as int,
        doubanDetails: freezed == doubanDetails
            ? _self.doubanDetails
            : doubanDetails // ignore: cast_nullable_to_non_nullable
                  as DoubanMovieDetails?,
        currentSource: null == currentSource
            ? _self.currentSource
            : currentSource // ignore: cast_nullable_to_non_nullable
                  as String,
        currentId: null == currentId
            ? _self.currentId
            : currentId // ignore: cast_nullable_to_non_nullable
                  as String,
        preferSource: null == preferSource
            ? _self.preferSource
            : preferSource // ignore: cast_nullable_to_non_nullable
                  as bool,
        totalEpisodes: null == totalEpisodes
            ? _self.totalEpisodes
            : totalEpisodes // ignore: cast_nullable_to_non_nullable
                  as int,
        currentEpisodeIndex: null == currentEpisodeIndex
            ? _self.currentEpisodeIndex
            : currentEpisodeIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        favorite: null == favorite
            ? _self.favorite
            : favorite // ignore: cast_nullable_to_non_nullable
                  as bool,
        loading: null == loading
            ? _self.loading
            : loading // ignore: cast_nullable_to_non_nullable
                  as bool,
        loadingProgress: null == loadingProgress
            ? _self.loadingProgress
            : loadingProgress // ignore: cast_nullable_to_non_nullable
                  as double,
        loadingMessage: null == loadingMessage
            ? _self.loadingMessage
            : loadingMessage // ignore: cast_nullable_to_non_nullable
                  as String,
        loadingEmoji: null == loadingEmoji
            ? _self.loadingEmoji
            : loadingEmoji // ignore: cast_nullable_to_non_nullable
                  as String,
        errorMessage: freezed == errorMessage
            ? _self.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        warningMessage: freezed == warningMessage
            ? _self.warningMessage
            : warningMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        resumeEpisodeIndex: null == resumeEpisodeIndex
            ? _self.resumeEpisodeIndex
            : resumeEpisodeIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        resumePlayTime: null == resumePlayTime
            ? _self.resumePlayTime
            : resumePlayTime // ignore: cast_nullable_to_non_nullable
                  as int,
        sources: null == sources
            ? _self._sources
            : sources // ignore: cast_nullable_to_non_nullable
                  as List<SearchResult>,
        sourceSpeeds: null == sourceSpeeds
            ? _self._sourceSpeeds
            : sourceSpeeds // ignore: cast_nullable_to_non_nullable
                  as Map<String, PlayerSourceSpeed>,
      ),
    );
  }
}
