import 'package:family_budget/features/family/models/family.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/cache/cache_pods.dart';
import '../repository/family_repository.dart';

part 'family_pod.g.dart';

@Riverpod(keepAlive: true)
class FamilyNotifier extends _$FamilyNotifier {
  @override
  FutureOr<Family?> build() async {
    final cache = ref.watch(appCacheProvider);
    final repository = ref.watch(familyRepositoryProvider);

    final activeIdRaw = await cache.getRaw(namespace: 'auth', key: 'active_family_id') as String?;

    if (activeIdRaw == null) return null;

    final id = int.tryParse(activeIdRaw);
    if (id == null) return null;

    try {
      return await repository.getFamily(id);
    } catch (e) {
      return null;
    }
  }

  Future<void> createFamily(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await ref.read(familyRepositoryProvider).create(name);
    });

    ref.invalidate(userFamiliesListProvider);
  }

  Future<void> joinFamily(String code) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await ref.read(familyRepositoryProvider).join(code);
    });

    ref.invalidate(userFamiliesListProvider);
  }

  Future<void> switchFamily(int familyId) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final cache = ref.read(appCacheProvider);
      final repository = ref.read(familyRepositoryProvider);

      await cache.putRaw(namespace: 'auth', key: 'active_family_id', value: familyId.toString());

      return await repository.getFamily(familyId);
    });
  }

  Future<void> clearCacheForTest() async {
    final cache = ref.read(appCacheProvider);
    await cache.remove(namespace: 'auth', key: 'active_family_id');
    state = const AsyncData(null);
  }
}


@riverpod
Future<List<Family>> userFamiliesList(Ref ref) async {
  final repository = ref.watch(familyRepositoryProvider);
  return repository.getList();
}