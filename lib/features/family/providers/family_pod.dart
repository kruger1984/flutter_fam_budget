import 'package:family_budget/features/family/models/family.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../repository/family_repository.dart';

part 'family_pod.g.dart';

@riverpod
class FamilyNotifier extends _$FamilyNotifier {
  @override
  FutureOr<Family?> build() async {
    return null;
  }

  Future<void> createFamily(String name) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(familyRepositoryProvider);
      final newFamily = await repository.create(name);

      return newFamily;
    });
  }

  Future<void> joinFamily(String code) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(familyRepositoryProvider);
      final joinedFamily = await repository.join(code);
      return joinedFamily;
    });
  }
}
