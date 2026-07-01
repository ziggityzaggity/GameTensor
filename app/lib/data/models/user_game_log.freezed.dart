// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_game_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserGameLog _$UserGameLogFromJson(Map<String, dynamic> json) {
  return _UserGameLog.fromJson(json);
}

/// @nodoc
mixin _$UserGameLog {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get gameId => throw _privateConstructorUsedError;
  int get completionStatusId => throw _privateConstructorUsedError;
  bool? get liked => throw _privateConstructorUsedError;
  double? get hoursPlayed => throw _privateConstructorUsedError;
  String get hoursSource => throw _privateConstructorUsedError;
  String? get lastPlayedAt => throw _privateConstructorUsedError;
  String? get startedAt => throw _privateConstructorUsedError;
  String? get finishedAt => throw _privateConstructorUsedError;
  bool get isFavorite => throw _privateConstructorUsedError;

  /// Serializes this UserGameLog to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserGameLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserGameLogCopyWith<UserGameLog> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserGameLogCopyWith<$Res> {
  factory $UserGameLogCopyWith(
          UserGameLog value, $Res Function(UserGameLog) then) =
      _$UserGameLogCopyWithImpl<$Res, UserGameLog>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String gameId,
      int completionStatusId,
      bool? liked,
      double? hoursPlayed,
      String hoursSource,
      String? lastPlayedAt,
      String? startedAt,
      String? finishedAt,
      bool isFavorite});
}

/// @nodoc
class _$UserGameLogCopyWithImpl<$Res, $Val extends UserGameLog>
    implements $UserGameLogCopyWith<$Res> {
  _$UserGameLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserGameLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? gameId = null,
    Object? completionStatusId = null,
    Object? liked = freezed,
    Object? hoursPlayed = freezed,
    Object? hoursSource = null,
    Object? lastPlayedAt = freezed,
    Object? startedAt = freezed,
    Object? finishedAt = freezed,
    Object? isFavorite = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String,
      completionStatusId: null == completionStatusId
          ? _value.completionStatusId
          : completionStatusId // ignore: cast_nullable_to_non_nullable
              as int,
      liked: freezed == liked
          ? _value.liked
          : liked // ignore: cast_nullable_to_non_nullable
              as bool?,
      hoursPlayed: freezed == hoursPlayed
          ? _value.hoursPlayed
          : hoursPlayed // ignore: cast_nullable_to_non_nullable
              as double?,
      hoursSource: null == hoursSource
          ? _value.hoursSource
          : hoursSource // ignore: cast_nullable_to_non_nullable
              as String,
      lastPlayedAt: freezed == lastPlayedAt
          ? _value.lastPlayedAt
          : lastPlayedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      finishedAt: freezed == finishedAt
          ? _value.finishedAt
          : finishedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserGameLogImplCopyWith<$Res>
    implements $UserGameLogCopyWith<$Res> {
  factory _$$UserGameLogImplCopyWith(
          _$UserGameLogImpl value, $Res Function(_$UserGameLogImpl) then) =
      __$$UserGameLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String gameId,
      int completionStatusId,
      bool? liked,
      double? hoursPlayed,
      String hoursSource,
      String? lastPlayedAt,
      String? startedAt,
      String? finishedAt,
      bool isFavorite});
}

/// @nodoc
class __$$UserGameLogImplCopyWithImpl<$Res>
    extends _$UserGameLogCopyWithImpl<$Res, _$UserGameLogImpl>
    implements _$$UserGameLogImplCopyWith<$Res> {
  __$$UserGameLogImplCopyWithImpl(
      _$UserGameLogImpl _value, $Res Function(_$UserGameLogImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserGameLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? gameId = null,
    Object? completionStatusId = null,
    Object? liked = freezed,
    Object? hoursPlayed = freezed,
    Object? hoursSource = null,
    Object? lastPlayedAt = freezed,
    Object? startedAt = freezed,
    Object? finishedAt = freezed,
    Object? isFavorite = null,
  }) {
    return _then(_$UserGameLogImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String,
      completionStatusId: null == completionStatusId
          ? _value.completionStatusId
          : completionStatusId // ignore: cast_nullable_to_non_nullable
              as int,
      liked: freezed == liked
          ? _value.liked
          : liked // ignore: cast_nullable_to_non_nullable
              as bool?,
      hoursPlayed: freezed == hoursPlayed
          ? _value.hoursPlayed
          : hoursPlayed // ignore: cast_nullable_to_non_nullable
              as double?,
      hoursSource: null == hoursSource
          ? _value.hoursSource
          : hoursSource // ignore: cast_nullable_to_non_nullable
              as String,
      lastPlayedAt: freezed == lastPlayedAt
          ? _value.lastPlayedAt
          : lastPlayedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      finishedAt: freezed == finishedAt
          ? _value.finishedAt
          : finishedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserGameLogImpl implements _UserGameLog {
  const _$UserGameLogImpl(
      {required this.id,
      required this.userId,
      required this.gameId,
      required this.completionStatusId,
      this.liked,
      this.hoursPlayed,
      this.hoursSource = 'manual',
      this.lastPlayedAt,
      this.startedAt,
      this.finishedAt,
      this.isFavorite = false});

  factory _$UserGameLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserGameLogImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String gameId;
  @override
  final int completionStatusId;
  @override
  final bool? liked;
  @override
  final double? hoursPlayed;
  @override
  @JsonKey()
  final String hoursSource;
  @override
  final String? lastPlayedAt;
  @override
  final String? startedAt;
  @override
  final String? finishedAt;
  @override
  @JsonKey()
  final bool isFavorite;

  @override
  String toString() {
    return 'UserGameLog(id: $id, userId: $userId, gameId: $gameId, completionStatusId: $completionStatusId, liked: $liked, hoursPlayed: $hoursPlayed, hoursSource: $hoursSource, lastPlayedAt: $lastPlayedAt, startedAt: $startedAt, finishedAt: $finishedAt, isFavorite: $isFavorite)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserGameLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            (identical(other.completionStatusId, completionStatusId) ||
                other.completionStatusId == completionStatusId) &&
            (identical(other.liked, liked) || other.liked == liked) &&
            (identical(other.hoursPlayed, hoursPlayed) ||
                other.hoursPlayed == hoursPlayed) &&
            (identical(other.hoursSource, hoursSource) ||
                other.hoursSource == hoursSource) &&
            (identical(other.lastPlayedAt, lastPlayedAt) ||
                other.lastPlayedAt == lastPlayedAt) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.finishedAt, finishedAt) ||
                other.finishedAt == finishedAt) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      gameId,
      completionStatusId,
      liked,
      hoursPlayed,
      hoursSource,
      lastPlayedAt,
      startedAt,
      finishedAt,
      isFavorite);

  /// Create a copy of UserGameLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserGameLogImplCopyWith<_$UserGameLogImpl> get copyWith =>
      __$$UserGameLogImplCopyWithImpl<_$UserGameLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserGameLogImplToJson(
      this,
    );
  }
}

abstract class _UserGameLog implements UserGameLog {
  const factory _UserGameLog(
      {required final String id,
      required final String userId,
      required final String gameId,
      required final int completionStatusId,
      final bool? liked,
      final double? hoursPlayed,
      final String hoursSource,
      final String? lastPlayedAt,
      final String? startedAt,
      final String? finishedAt,
      final bool isFavorite}) = _$UserGameLogImpl;

  factory _UserGameLog.fromJson(Map<String, dynamic> json) =
      _$UserGameLogImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get gameId;
  @override
  int get completionStatusId;
  @override
  bool? get liked;
  @override
  double? get hoursPlayed;
  @override
  String get hoursSource;
  @override
  String? get lastPlayedAt;
  @override
  String? get startedAt;
  @override
  String? get finishedAt;
  @override
  bool get isFavorite;

  /// Create a copy of UserGameLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserGameLogImplCopyWith<_$UserGameLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
