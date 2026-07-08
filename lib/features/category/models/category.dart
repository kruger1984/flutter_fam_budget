import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_icon.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
abstract class Category with _$Category {
  const Category._();

  const factory Category({
    required int id,
    required String name,
    @JsonKey(unknownEnumValue: AppIcon.question) AppIcon? icon,
    String? color,
    @JsonKey(name: 'parent_id') int? parentId,
    @JsonKey(name: 'family_id') int? familyId,
    @Default([]) List<Category> children,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);

  bool get isRoot => parentId == null;
  bool get isSystem => familyId == null;
}
