import 'package:freezed_annotation/freezed_annotation.dart';

part 'custom_list.freezed.dart';
part 'custom_list.g.dart';

enum ListVisibility {
  @JsonValue('private')
  private,
  @JsonValue('friends')
  friends,
  @JsonValue('public')
  public,
}

@freezed
class CustomList with _$CustomList {
  const factory CustomList({
    required String id,
    required String ownerId,
    required String title,
    String? description,
    @Default(ListVisibility.private) ListVisibility visibility,
    String? coverImageUrl,
  }) = _CustomList;

  factory CustomList.fromJson(Map<String, dynamic> json) =>
      _$CustomListFromJson(json);
}

@freezed
class ListItem with _$ListItem {
  const factory ListItem({
    required String id,
    required String listId,
    required String gameId,
    required int position,
    String? note,
  }) = _ListItem;

  factory ListItem.fromJson(Map<String, dynamic> json) =>
      _$ListItemFromJson(json);
}
