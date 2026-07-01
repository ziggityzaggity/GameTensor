// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Game _$GameFromJson(Map<String, dynamic> json) {
  return _Game.fromJson(json);
}

/// @nodoc
mixin _$Game {
  String get id => throw _privateConstructorUsedError;
  GameKind get kind => throw _privateConstructorUsedError;
  String get canonicalName => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String? get summary => throw _privateConstructorUsedError;
  String? get releaseDate => throw _privateConstructorUsedError;
  String? get coverImageUrl => throw _privateConstructorUsedError;
  int? get igdbId => throw _privateConstructorUsedError;
  int? get bggId => throw _privateConstructorUsedError;
  double? get popularityScore => throw _privateConstructorUsedError;
  VideoGameDetails? get videoGameDetails => throw _privateConstructorUsedError;
  TabletopGameDetails? get tabletopGameDetails =>
      throw _privateConstructorUsedError;

  /// Serializes this Game to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameCopyWith<Game> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameCopyWith<$Res> {
  factory $GameCopyWith(Game value, $Res Function(Game) then) =
      _$GameCopyWithImpl<$Res, Game>;
  @useResult
  $Res call(
      {String id,
      GameKind kind,
      String canonicalName,
      String slug,
      String? summary,
      String? releaseDate,
      String? coverImageUrl,
      int? igdbId,
      int? bggId,
      double? popularityScore,
      VideoGameDetails? videoGameDetails,
      TabletopGameDetails? tabletopGameDetails});

  $VideoGameDetailsCopyWith<$Res>? get videoGameDetails;
  $TabletopGameDetailsCopyWith<$Res>? get tabletopGameDetails;
}

/// @nodoc
class _$GameCopyWithImpl<$Res, $Val extends Game>
    implements $GameCopyWith<$Res> {
  _$GameCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? canonicalName = null,
    Object? slug = null,
    Object? summary = freezed,
    Object? releaseDate = freezed,
    Object? coverImageUrl = freezed,
    Object? igdbId = freezed,
    Object? bggId = freezed,
    Object? popularityScore = freezed,
    Object? videoGameDetails = freezed,
    Object? tabletopGameDetails = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as GameKind,
      canonicalName: null == canonicalName
          ? _value.canonicalName
          : canonicalName // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      summary: freezed == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as String?,
      releaseDate: freezed == releaseDate
          ? _value.releaseDate
          : releaseDate // ignore: cast_nullable_to_non_nullable
              as String?,
      coverImageUrl: freezed == coverImageUrl
          ? _value.coverImageUrl
          : coverImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      igdbId: freezed == igdbId
          ? _value.igdbId
          : igdbId // ignore: cast_nullable_to_non_nullable
              as int?,
      bggId: freezed == bggId
          ? _value.bggId
          : bggId // ignore: cast_nullable_to_non_nullable
              as int?,
      popularityScore: freezed == popularityScore
          ? _value.popularityScore
          : popularityScore // ignore: cast_nullable_to_non_nullable
              as double?,
      videoGameDetails: freezed == videoGameDetails
          ? _value.videoGameDetails
          : videoGameDetails // ignore: cast_nullable_to_non_nullable
              as VideoGameDetails?,
      tabletopGameDetails: freezed == tabletopGameDetails
          ? _value.tabletopGameDetails
          : tabletopGameDetails // ignore: cast_nullable_to_non_nullable
              as TabletopGameDetails?,
    ) as $Val);
  }

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VideoGameDetailsCopyWith<$Res>? get videoGameDetails {
    if (_value.videoGameDetails == null) {
      return null;
    }

    return $VideoGameDetailsCopyWith<$Res>(_value.videoGameDetails!, (value) {
      return _then(_value.copyWith(videoGameDetails: value) as $Val);
    });
  }

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TabletopGameDetailsCopyWith<$Res>? get tabletopGameDetails {
    if (_value.tabletopGameDetails == null) {
      return null;
    }

    return $TabletopGameDetailsCopyWith<$Res>(_value.tabletopGameDetails!,
        (value) {
      return _then(_value.copyWith(tabletopGameDetails: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GameImplCopyWith<$Res> implements $GameCopyWith<$Res> {
  factory _$$GameImplCopyWith(
          _$GameImpl value, $Res Function(_$GameImpl) then) =
      __$$GameImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      GameKind kind,
      String canonicalName,
      String slug,
      String? summary,
      String? releaseDate,
      String? coverImageUrl,
      int? igdbId,
      int? bggId,
      double? popularityScore,
      VideoGameDetails? videoGameDetails,
      TabletopGameDetails? tabletopGameDetails});

  @override
  $VideoGameDetailsCopyWith<$Res>? get videoGameDetails;
  @override
  $TabletopGameDetailsCopyWith<$Res>? get tabletopGameDetails;
}

/// @nodoc
class __$$GameImplCopyWithImpl<$Res>
    extends _$GameCopyWithImpl<$Res, _$GameImpl>
    implements _$$GameImplCopyWith<$Res> {
  __$$GameImplCopyWithImpl(_$GameImpl _value, $Res Function(_$GameImpl) _then)
      : super(_value, _then);

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? canonicalName = null,
    Object? slug = null,
    Object? summary = freezed,
    Object? releaseDate = freezed,
    Object? coverImageUrl = freezed,
    Object? igdbId = freezed,
    Object? bggId = freezed,
    Object? popularityScore = freezed,
    Object? videoGameDetails = freezed,
    Object? tabletopGameDetails = freezed,
  }) {
    return _then(_$GameImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as GameKind,
      canonicalName: null == canonicalName
          ? _value.canonicalName
          : canonicalName // ignore: cast_nullable_to_non_nullable
              as String,
      slug: null == slug
          ? _value.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      summary: freezed == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as String?,
      releaseDate: freezed == releaseDate
          ? _value.releaseDate
          : releaseDate // ignore: cast_nullable_to_non_nullable
              as String?,
      coverImageUrl: freezed == coverImageUrl
          ? _value.coverImageUrl
          : coverImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      igdbId: freezed == igdbId
          ? _value.igdbId
          : igdbId // ignore: cast_nullable_to_non_nullable
              as int?,
      bggId: freezed == bggId
          ? _value.bggId
          : bggId // ignore: cast_nullable_to_non_nullable
              as int?,
      popularityScore: freezed == popularityScore
          ? _value.popularityScore
          : popularityScore // ignore: cast_nullable_to_non_nullable
              as double?,
      videoGameDetails: freezed == videoGameDetails
          ? _value.videoGameDetails
          : videoGameDetails // ignore: cast_nullable_to_non_nullable
              as VideoGameDetails?,
      tabletopGameDetails: freezed == tabletopGameDetails
          ? _value.tabletopGameDetails
          : tabletopGameDetails // ignore: cast_nullable_to_non_nullable
              as TabletopGameDetails?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GameImpl implements _Game {
  const _$GameImpl(
      {required this.id,
      required this.kind,
      required this.canonicalName,
      required this.slug,
      this.summary,
      this.releaseDate,
      this.coverImageUrl,
      this.igdbId,
      this.bggId,
      this.popularityScore,
      this.videoGameDetails,
      this.tabletopGameDetails});

  factory _$GameImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameImplFromJson(json);

  @override
  final String id;
  @override
  final GameKind kind;
  @override
  final String canonicalName;
  @override
  final String slug;
  @override
  final String? summary;
  @override
  final String? releaseDate;
  @override
  final String? coverImageUrl;
  @override
  final int? igdbId;
  @override
  final int? bggId;
  @override
  final double? popularityScore;
  @override
  final VideoGameDetails? videoGameDetails;
  @override
  final TabletopGameDetails? tabletopGameDetails;

  @override
  String toString() {
    return 'Game(id: $id, kind: $kind, canonicalName: $canonicalName, slug: $slug, summary: $summary, releaseDate: $releaseDate, coverImageUrl: $coverImageUrl, igdbId: $igdbId, bggId: $bggId, popularityScore: $popularityScore, videoGameDetails: $videoGameDetails, tabletopGameDetails: $tabletopGameDetails)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.canonicalName, canonicalName) ||
                other.canonicalName == canonicalName) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.releaseDate, releaseDate) ||
                other.releaseDate == releaseDate) &&
            (identical(other.coverImageUrl, coverImageUrl) ||
                other.coverImageUrl == coverImageUrl) &&
            (identical(other.igdbId, igdbId) || other.igdbId == igdbId) &&
            (identical(other.bggId, bggId) || other.bggId == bggId) &&
            (identical(other.popularityScore, popularityScore) ||
                other.popularityScore == popularityScore) &&
            (identical(other.videoGameDetails, videoGameDetails) ||
                other.videoGameDetails == videoGameDetails) &&
            (identical(other.tabletopGameDetails, tabletopGameDetails) ||
                other.tabletopGameDetails == tabletopGameDetails));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      kind,
      canonicalName,
      slug,
      summary,
      releaseDate,
      coverImageUrl,
      igdbId,
      bggId,
      popularityScore,
      videoGameDetails,
      tabletopGameDetails);

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameImplCopyWith<_$GameImpl> get copyWith =>
      __$$GameImplCopyWithImpl<_$GameImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameImplToJson(
      this,
    );
  }
}

abstract class _Game implements Game {
  const factory _Game(
      {required final String id,
      required final GameKind kind,
      required final String canonicalName,
      required final String slug,
      final String? summary,
      final String? releaseDate,
      final String? coverImageUrl,
      final int? igdbId,
      final int? bggId,
      final double? popularityScore,
      final VideoGameDetails? videoGameDetails,
      final TabletopGameDetails? tabletopGameDetails}) = _$GameImpl;

  factory _Game.fromJson(Map<String, dynamic> json) = _$GameImpl.fromJson;

  @override
  String get id;
  @override
  GameKind get kind;
  @override
  String get canonicalName;
  @override
  String get slug;
  @override
  String? get summary;
  @override
  String? get releaseDate;
  @override
  String? get coverImageUrl;
  @override
  int? get igdbId;
  @override
  int? get bggId;
  @override
  double? get popularityScore;
  @override
  VideoGameDetails? get videoGameDetails;
  @override
  TabletopGameDetails? get tabletopGameDetails;

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameImplCopyWith<_$GameImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VideoGameDetails _$VideoGameDetailsFromJson(Map<String, dynamic> json) {
  return _VideoGameDetails.fromJson(json);
}

/// @nodoc
mixin _$VideoGameDetails {
  String get gameId => throw _privateConstructorUsedError;
  String? get igdbSlug => throw _privateConstructorUsedError;
  String? get franchise => throw _privateConstructorUsedError;
  List<String>? get gameModes => throw _privateConstructorUsedError;
  String? get esrbRating => throw _privateConstructorUsedError;
  int? get metacriticScore => throw _privateConstructorUsedError;

  /// Serializes this VideoGameDetails to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VideoGameDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VideoGameDetailsCopyWith<VideoGameDetails> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VideoGameDetailsCopyWith<$Res> {
  factory $VideoGameDetailsCopyWith(
          VideoGameDetails value, $Res Function(VideoGameDetails) then) =
      _$VideoGameDetailsCopyWithImpl<$Res, VideoGameDetails>;
  @useResult
  $Res call(
      {String gameId,
      String? igdbSlug,
      String? franchise,
      List<String>? gameModes,
      String? esrbRating,
      int? metacriticScore});
}

/// @nodoc
class _$VideoGameDetailsCopyWithImpl<$Res, $Val extends VideoGameDetails>
    implements $VideoGameDetailsCopyWith<$Res> {
  _$VideoGameDetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VideoGameDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? igdbSlug = freezed,
    Object? franchise = freezed,
    Object? gameModes = freezed,
    Object? esrbRating = freezed,
    Object? metacriticScore = freezed,
  }) {
    return _then(_value.copyWith(
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String,
      igdbSlug: freezed == igdbSlug
          ? _value.igdbSlug
          : igdbSlug // ignore: cast_nullable_to_non_nullable
              as String?,
      franchise: freezed == franchise
          ? _value.franchise
          : franchise // ignore: cast_nullable_to_non_nullable
              as String?,
      gameModes: freezed == gameModes
          ? _value.gameModes
          : gameModes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      esrbRating: freezed == esrbRating
          ? _value.esrbRating
          : esrbRating // ignore: cast_nullable_to_non_nullable
              as String?,
      metacriticScore: freezed == metacriticScore
          ? _value.metacriticScore
          : metacriticScore // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VideoGameDetailsImplCopyWith<$Res>
    implements $VideoGameDetailsCopyWith<$Res> {
  factory _$$VideoGameDetailsImplCopyWith(_$VideoGameDetailsImpl value,
          $Res Function(_$VideoGameDetailsImpl) then) =
      __$$VideoGameDetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String gameId,
      String? igdbSlug,
      String? franchise,
      List<String>? gameModes,
      String? esrbRating,
      int? metacriticScore});
}

/// @nodoc
class __$$VideoGameDetailsImplCopyWithImpl<$Res>
    extends _$VideoGameDetailsCopyWithImpl<$Res, _$VideoGameDetailsImpl>
    implements _$$VideoGameDetailsImplCopyWith<$Res> {
  __$$VideoGameDetailsImplCopyWithImpl(_$VideoGameDetailsImpl _value,
      $Res Function(_$VideoGameDetailsImpl) _then)
      : super(_value, _then);

  /// Create a copy of VideoGameDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? igdbSlug = freezed,
    Object? franchise = freezed,
    Object? gameModes = freezed,
    Object? esrbRating = freezed,
    Object? metacriticScore = freezed,
  }) {
    return _then(_$VideoGameDetailsImpl(
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String,
      igdbSlug: freezed == igdbSlug
          ? _value.igdbSlug
          : igdbSlug // ignore: cast_nullable_to_non_nullable
              as String?,
      franchise: freezed == franchise
          ? _value.franchise
          : franchise // ignore: cast_nullable_to_non_nullable
              as String?,
      gameModes: freezed == gameModes
          ? _value._gameModes
          : gameModes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      esrbRating: freezed == esrbRating
          ? _value.esrbRating
          : esrbRating // ignore: cast_nullable_to_non_nullable
              as String?,
      metacriticScore: freezed == metacriticScore
          ? _value.metacriticScore
          : metacriticScore // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VideoGameDetailsImpl implements _VideoGameDetails {
  const _$VideoGameDetailsImpl(
      {required this.gameId,
      this.igdbSlug,
      this.franchise,
      final List<String>? gameModes,
      this.esrbRating,
      this.metacriticScore})
      : _gameModes = gameModes;

  factory _$VideoGameDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$VideoGameDetailsImplFromJson(json);

  @override
  final String gameId;
  @override
  final String? igdbSlug;
  @override
  final String? franchise;
  final List<String>? _gameModes;
  @override
  List<String>? get gameModes {
    final value = _gameModes;
    if (value == null) return null;
    if (_gameModes is EqualUnmodifiableListView) return _gameModes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? esrbRating;
  @override
  final int? metacriticScore;

  @override
  String toString() {
    return 'VideoGameDetails(gameId: $gameId, igdbSlug: $igdbSlug, franchise: $franchise, gameModes: $gameModes, esrbRating: $esrbRating, metacriticScore: $metacriticScore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoGameDetailsImpl &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            (identical(other.igdbSlug, igdbSlug) ||
                other.igdbSlug == igdbSlug) &&
            (identical(other.franchise, franchise) ||
                other.franchise == franchise) &&
            const DeepCollectionEquality()
                .equals(other._gameModes, _gameModes) &&
            (identical(other.esrbRating, esrbRating) ||
                other.esrbRating == esrbRating) &&
            (identical(other.metacriticScore, metacriticScore) ||
                other.metacriticScore == metacriticScore));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      gameId,
      igdbSlug,
      franchise,
      const DeepCollectionEquality().hash(_gameModes),
      esrbRating,
      metacriticScore);

  /// Create a copy of VideoGameDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoGameDetailsImplCopyWith<_$VideoGameDetailsImpl> get copyWith =>
      __$$VideoGameDetailsImplCopyWithImpl<_$VideoGameDetailsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VideoGameDetailsImplToJson(
      this,
    );
  }
}

abstract class _VideoGameDetails implements VideoGameDetails {
  const factory _VideoGameDetails(
      {required final String gameId,
      final String? igdbSlug,
      final String? franchise,
      final List<String>? gameModes,
      final String? esrbRating,
      final int? metacriticScore}) = _$VideoGameDetailsImpl;

  factory _VideoGameDetails.fromJson(Map<String, dynamic> json) =
      _$VideoGameDetailsImpl.fromJson;

  @override
  String get gameId;
  @override
  String? get igdbSlug;
  @override
  String? get franchise;
  @override
  List<String>? get gameModes;
  @override
  String? get esrbRating;
  @override
  int? get metacriticScore;

  /// Create a copy of VideoGameDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoGameDetailsImplCopyWith<_$VideoGameDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TabletopGameDetails _$TabletopGameDetailsFromJson(Map<String, dynamic> json) {
  return _TabletopGameDetails.fromJson(json);
}

/// @nodoc
mixin _$TabletopGameDetails {
  String get gameId => throw _privateConstructorUsedError;
  String? get bggType => throw _privateConstructorUsedError;
  int? get minPlayers => throw _privateConstructorUsedError;
  int? get maxPlayers => throw _privateConstructorUsedError;
  int? get minPlaytimeMinutes => throw _privateConstructorUsedError;
  int? get maxPlaytimeMinutes => throw _privateConstructorUsedError;
  int? get minAge => throw _privateConstructorUsedError;
  int? get bggRank => throw _privateConstructorUsedError;
  double? get bggAverageRating => throw _privateConstructorUsedError;

  /// Serializes this TabletopGameDetails to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TabletopGameDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TabletopGameDetailsCopyWith<TabletopGameDetails> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TabletopGameDetailsCopyWith<$Res> {
  factory $TabletopGameDetailsCopyWith(
          TabletopGameDetails value, $Res Function(TabletopGameDetails) then) =
      _$TabletopGameDetailsCopyWithImpl<$Res, TabletopGameDetails>;
  @useResult
  $Res call(
      {String gameId,
      String? bggType,
      int? minPlayers,
      int? maxPlayers,
      int? minPlaytimeMinutes,
      int? maxPlaytimeMinutes,
      int? minAge,
      int? bggRank,
      double? bggAverageRating});
}

/// @nodoc
class _$TabletopGameDetailsCopyWithImpl<$Res, $Val extends TabletopGameDetails>
    implements $TabletopGameDetailsCopyWith<$Res> {
  _$TabletopGameDetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TabletopGameDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? bggType = freezed,
    Object? minPlayers = freezed,
    Object? maxPlayers = freezed,
    Object? minPlaytimeMinutes = freezed,
    Object? maxPlaytimeMinutes = freezed,
    Object? minAge = freezed,
    Object? bggRank = freezed,
    Object? bggAverageRating = freezed,
  }) {
    return _then(_value.copyWith(
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String,
      bggType: freezed == bggType
          ? _value.bggType
          : bggType // ignore: cast_nullable_to_non_nullable
              as String?,
      minPlayers: freezed == minPlayers
          ? _value.minPlayers
          : minPlayers // ignore: cast_nullable_to_non_nullable
              as int?,
      maxPlayers: freezed == maxPlayers
          ? _value.maxPlayers
          : maxPlayers // ignore: cast_nullable_to_non_nullable
              as int?,
      minPlaytimeMinutes: freezed == minPlaytimeMinutes
          ? _value.minPlaytimeMinutes
          : minPlaytimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      maxPlaytimeMinutes: freezed == maxPlaytimeMinutes
          ? _value.maxPlaytimeMinutes
          : maxPlaytimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      minAge: freezed == minAge
          ? _value.minAge
          : minAge // ignore: cast_nullable_to_non_nullable
              as int?,
      bggRank: freezed == bggRank
          ? _value.bggRank
          : bggRank // ignore: cast_nullable_to_non_nullable
              as int?,
      bggAverageRating: freezed == bggAverageRating
          ? _value.bggAverageRating
          : bggAverageRating // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TabletopGameDetailsImplCopyWith<$Res>
    implements $TabletopGameDetailsCopyWith<$Res> {
  factory _$$TabletopGameDetailsImplCopyWith(_$TabletopGameDetailsImpl value,
          $Res Function(_$TabletopGameDetailsImpl) then) =
      __$$TabletopGameDetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String gameId,
      String? bggType,
      int? minPlayers,
      int? maxPlayers,
      int? minPlaytimeMinutes,
      int? maxPlaytimeMinutes,
      int? minAge,
      int? bggRank,
      double? bggAverageRating});
}

/// @nodoc
class __$$TabletopGameDetailsImplCopyWithImpl<$Res>
    extends _$TabletopGameDetailsCopyWithImpl<$Res, _$TabletopGameDetailsImpl>
    implements _$$TabletopGameDetailsImplCopyWith<$Res> {
  __$$TabletopGameDetailsImplCopyWithImpl(_$TabletopGameDetailsImpl _value,
      $Res Function(_$TabletopGameDetailsImpl) _then)
      : super(_value, _then);

  /// Create a copy of TabletopGameDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? bggType = freezed,
    Object? minPlayers = freezed,
    Object? maxPlayers = freezed,
    Object? minPlaytimeMinutes = freezed,
    Object? maxPlaytimeMinutes = freezed,
    Object? minAge = freezed,
    Object? bggRank = freezed,
    Object? bggAverageRating = freezed,
  }) {
    return _then(_$TabletopGameDetailsImpl(
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String,
      bggType: freezed == bggType
          ? _value.bggType
          : bggType // ignore: cast_nullable_to_non_nullable
              as String?,
      minPlayers: freezed == minPlayers
          ? _value.minPlayers
          : minPlayers // ignore: cast_nullable_to_non_nullable
              as int?,
      maxPlayers: freezed == maxPlayers
          ? _value.maxPlayers
          : maxPlayers // ignore: cast_nullable_to_non_nullable
              as int?,
      minPlaytimeMinutes: freezed == minPlaytimeMinutes
          ? _value.minPlaytimeMinutes
          : minPlaytimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      maxPlaytimeMinutes: freezed == maxPlaytimeMinutes
          ? _value.maxPlaytimeMinutes
          : maxPlaytimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      minAge: freezed == minAge
          ? _value.minAge
          : minAge // ignore: cast_nullable_to_non_nullable
              as int?,
      bggRank: freezed == bggRank
          ? _value.bggRank
          : bggRank // ignore: cast_nullable_to_non_nullable
              as int?,
      bggAverageRating: freezed == bggAverageRating
          ? _value.bggAverageRating
          : bggAverageRating // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TabletopGameDetailsImpl implements _TabletopGameDetails {
  const _$TabletopGameDetailsImpl(
      {required this.gameId,
      this.bggType,
      this.minPlayers,
      this.maxPlayers,
      this.minPlaytimeMinutes,
      this.maxPlaytimeMinutes,
      this.minAge,
      this.bggRank,
      this.bggAverageRating});

  factory _$TabletopGameDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$TabletopGameDetailsImplFromJson(json);

  @override
  final String gameId;
  @override
  final String? bggType;
  @override
  final int? minPlayers;
  @override
  final int? maxPlayers;
  @override
  final int? minPlaytimeMinutes;
  @override
  final int? maxPlaytimeMinutes;
  @override
  final int? minAge;
  @override
  final int? bggRank;
  @override
  final double? bggAverageRating;

  @override
  String toString() {
    return 'TabletopGameDetails(gameId: $gameId, bggType: $bggType, minPlayers: $minPlayers, maxPlayers: $maxPlayers, minPlaytimeMinutes: $minPlaytimeMinutes, maxPlaytimeMinutes: $maxPlaytimeMinutes, minAge: $minAge, bggRank: $bggRank, bggAverageRating: $bggAverageRating)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TabletopGameDetailsImpl &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            (identical(other.bggType, bggType) || other.bggType == bggType) &&
            (identical(other.minPlayers, minPlayers) ||
                other.minPlayers == minPlayers) &&
            (identical(other.maxPlayers, maxPlayers) ||
                other.maxPlayers == maxPlayers) &&
            (identical(other.minPlaytimeMinutes, minPlaytimeMinutes) ||
                other.minPlaytimeMinutes == minPlaytimeMinutes) &&
            (identical(other.maxPlaytimeMinutes, maxPlaytimeMinutes) ||
                other.maxPlaytimeMinutes == maxPlaytimeMinutes) &&
            (identical(other.minAge, minAge) || other.minAge == minAge) &&
            (identical(other.bggRank, bggRank) || other.bggRank == bggRank) &&
            (identical(other.bggAverageRating, bggAverageRating) ||
                other.bggAverageRating == bggAverageRating));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      gameId,
      bggType,
      minPlayers,
      maxPlayers,
      minPlaytimeMinutes,
      maxPlaytimeMinutes,
      minAge,
      bggRank,
      bggAverageRating);

  /// Create a copy of TabletopGameDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TabletopGameDetailsImplCopyWith<_$TabletopGameDetailsImpl> get copyWith =>
      __$$TabletopGameDetailsImplCopyWithImpl<_$TabletopGameDetailsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TabletopGameDetailsImplToJson(
      this,
    );
  }
}

abstract class _TabletopGameDetails implements TabletopGameDetails {
  const factory _TabletopGameDetails(
      {required final String gameId,
      final String? bggType,
      final int? minPlayers,
      final int? maxPlayers,
      final int? minPlaytimeMinutes,
      final int? maxPlaytimeMinutes,
      final int? minAge,
      final int? bggRank,
      final double? bggAverageRating}) = _$TabletopGameDetailsImpl;

  factory _TabletopGameDetails.fromJson(Map<String, dynamic> json) =
      _$TabletopGameDetailsImpl.fromJson;

  @override
  String get gameId;
  @override
  String? get bggType;
  @override
  int? get minPlayers;
  @override
  int? get maxPlayers;
  @override
  int? get minPlaytimeMinutes;
  @override
  int? get maxPlaytimeMinutes;
  @override
  int? get minAge;
  @override
  int? get bggRank;
  @override
  double? get bggAverageRating;

  /// Create a copy of TabletopGameDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TabletopGameDetailsImplCopyWith<_$TabletopGameDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
