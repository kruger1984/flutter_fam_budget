import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repository/family_repository.dart';

part 'family_pod.g.dart';

@riverpod
class FamilyNotifier extends _$FamilyNotifier {
  @override
  FutureOr<dynamic> build() async {
    return _fetchData();
  }

  Future<dynamic> _fetchData() async {
    final repository = ref.read(familyRepositoryProvider);
    return null;
  }

  Future<void> performAction() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(familyRepositoryProvider);
      state = AsyncData(await _fetchData());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}