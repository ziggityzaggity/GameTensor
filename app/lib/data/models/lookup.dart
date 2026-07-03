import 'package:freezed_annotation/freezed_annotation.dart';

part 'lookup.freezed.dart';
part 'lookup.g.dart';

/// A row from the `genres` lookup table.
@freezed
class Genre with _$Genre {
  const factory Genre({
    required int id,
    required String code,
    required String displayName,
  }) = _Genre;

  factory Genre.fromJson(Map<String, dynamic> json) => _$GenreFromJson(json);
}

/// A row from the `platforms` lookup table.
@freezed
class Platform with _$Platform {
  const factory Platform({
    required int id,
    required String code,
    required String displayName,
  }) = _Platform;

  factory Platform.fromJson(Map<String, dynamic> json) =>
      _$PlatformFromJson(json);
}
