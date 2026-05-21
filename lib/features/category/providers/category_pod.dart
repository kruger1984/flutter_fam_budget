import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repository/category_repository.dart';

part 'category_pod.g.dart';

@riverpod
class CategoryNotifier extends _$CategoryNotifier {
  @override
  FutureOr<dynamic> build() async {
    return _fetchData();
  }

  Future<dynamic> _fetchData() async {
    final repository = ref.read(categoryRepositoryProvider);
    return null;
  }

  Future<void> performAction() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(categoryRepositoryProvider);
      state = AsyncData(await _fetchData());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}