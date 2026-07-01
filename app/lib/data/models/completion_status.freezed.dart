// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'completion_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CompletionStatus _$CompletionStatusFromJson(Map<String, dynamic> json) {
  return _CompletionStatus.fromJson(json);
}

/// @nodoc
mixin _$CompletionStatus {
  int get id => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;

  /// Serializes this CompletionStatus to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompletionStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompletionStatusCopyWith<CompletionStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompletionStatusCopyWith<$Res> {
  factory $CompletionStatusCopyWith(
          CompletionStatus value, $Res Function(CompletionStatus) then) =
      _$CompletionStatusCopyWithImpl<$Res, CompletionStatus>;
  @useResult
  $Res call({int id, String code, String label});
}

/// @nodoc
class _$CompletionStatusCopyWithImpl<$Res, $Val extends CompletionStatus>
    implements $CompletionStatusCopyWith<$Res> {
  _$CompletionStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompletionStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? label = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CompletionStatusImplCopyWith<$Res>
    implements $CompletionStatusCopyWith<$Res> {
  factory _$$CompletionStatusImplCopyWith(_$CompletionStatusImpl value,
          $Res Function(_$CompletionStatusImpl) then) =
      __$$CompletionStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String code, String label});
}

/// @nodoc
class __$$CompletionStatusImplCopyWithImpl<$Res>
    extends _$CompletionStatusCopyWithImpl<$Res, _$CompletionStatusImpl>
    implements _$$CompletionStatusImplCopyWith<$Res> {
  __$$CompletionStatusImplCopyWithImpl(_$CompletionStatusImpl _value,
      $Res Function(_$CompletionStatusImpl) _then)
      : super(_value, _then);

  /// Create a copy of CompletionStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? label = null,
  }) {
    return _then(_$CompletionStatusImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CompletionStatusImpl implements _CompletionStatus {
  const _$CompletionStatusImpl(
      {required this.id, required this.code, required this.label});

  factory _$CompletionStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompletionStatusImplFromJson(json);

  @override
  final int id;
  @override
  final String code;
  @override
  final String label;

  @override
  String toString() {
    return 'CompletionStatus(id: $id, code: $code, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompletionStatusImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.label, label) || other.label == label));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, code, label);

  /// Create a copy of CompletionStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompletionStatusImplCopyWith<_$CompletionStatusImpl> get copyWith =>
      __$$CompletionStatusImplCopyWithImpl<_$CompletionStatusImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CompletionStatusImplToJson(
      this,
    );
  }
}

abstract class _CompletionStatus implements CompletionStatus {
  const factory _CompletionStatus(
      {required final int id,
      required final String code,
      required final String label}) = _$CompletionStatusImpl;

  factory _CompletionStatus.fromJson(Map<String, dynamic> json) =
      _$CompletionStatusImpl.fromJson;

  @override
  int get id;
  @override
  String get code;
  @override
  String get label;

  /// Create a copy of CompletionStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompletionStatusImplCopyWith<_$CompletionStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
