import 'package:family_budget/features/family/models/role.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../auth/models/user.dart';

part 'family.freezed.dart';
part 'family.g.dart';

@freezed
abstract class Family with _$Family {
  const factory Family({
    required int id,
    required String name,
    required Role role,
    @JsonKey(name: 'owner') required User owner,
    @Default([]) List<User> users,
  }) = _Family;

  factory Family.fromJson(Map<String, dynamic> json) =>
      _$FamilyFromJson(json);
}