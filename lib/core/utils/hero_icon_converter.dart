import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:heroicons/heroicons.dart';

class HeroIconConverter implements JsonConverter<HeroIcons, String> {
  const HeroIconConverter();

  @override
  HeroIcons fromJson(String json) {
    final camelCaseName = json.split('-').map((word) {
      if (word.isEmpty) return '';
      return word == json.split('-').first
          ? word
          : word[0].toUpperCase() + word.substring(1);
    }).join('');

    return HeroIcons.values.firstWhere(
          (icon) => icon.name == camelCaseName,
      orElse: () => HeroIcons.questionMarkCircle,
    );
  }

  @override
  String toJson(HeroIcons object) {
    return object.name.replaceAllMapped(
      RegExp(r'[A-Z]'),
          (match) => '-${match.group(0)!.toLowerCase()}',
    );
  }
}