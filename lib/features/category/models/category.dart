import 'package:family_budget/core/utils/hero_icon_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:heroicons/heroicons.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
abstract class Category with _$Category {
  const Category._();

  const factory Category({
    required int id,
    required String name,
    @HeroIconConverter() HeroIcons? icon,
    String? color,
    @JsonKey(name: 'parent_id') int? parentId,
    @JsonKey(name: 'family_id') int? familyId,
    @Default([]) List<Category> children,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);

  bool get isRoot => parentId == null;
  bool get isSystem => familyId == null;
}
