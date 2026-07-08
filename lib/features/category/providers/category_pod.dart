import 'package:family_budget/features/category/models/category.dart';
import 'package:family_budget/features/category/repository/category_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/app_icon.dart';

part 'category_pod.g.dart';

@riverpod
class CategoryNotifier extends _$CategoryNotifier {
  @override
  FutureOr<List<Category>> build() async {
    final repository = ref.watch(categoryRepositoryProvider);
    return await repository.getList();
  }

  Future<void> createCategory({required String name, AppIcon? icon, String? color, int? parentId}) async {
    final previousState = state.value ?? [];
    state = const AsyncLoading();

    try {
      final newCategory = await ref.read(categoryRepositoryProvider).create(name: name, icon: icon, color: color, parentId: parentId);

      if (parentId == null) {
        state = AsyncData(<Category>[...previousState, newCategory]);
      } else {
        final newState = previousState.map((cat) {
          if (cat.id == parentId) {
            return cat.copyWith(children: <Category>[...cat.children, newCategory]);
          }
          return cat;
        }).toList();
        state = AsyncData(newState);
      }
    } catch (e) {
      state = AsyncData(previousState);
      rethrow;
    }
  }

  Future<void> updateCategory({required int id, required String name, AppIcon? icon, String? color, int? parentId}) async {
    final previousState = state.value ?? [];
    state = const AsyncLoading();

    try {
      final updatedCategory = await ref.read(categoryRepositoryProvider).update(
          id: id,
          name: name,
          icon: icon,
          color: color,
          parentId: parentId
      );

      final newState = previousState.map((cat) {
        if (cat.id == id) {
          return updatedCategory.copyWith(children: cat.children);
        }

        if (cat.children.any((child) => child.id == id)) {
          return cat.copyWith(
            children: cat.children.map((child) =>
            child.id == id ? updatedCategory : child
            ).toList(),
          );
        }

        return cat;
      }).toList();

      state = AsyncData(newState);
    } catch (e) {
      state = AsyncData(previousState);
      rethrow;
    }
  }
  Future<void> deleteCategory(int categoryId) async {
    final previousState = state.value ?? [];
    state = const AsyncLoading();

    try {
      await ref.read(categoryRepositoryProvider).delete(categoryId);

      var newState = previousState.where((cat) => cat.id != categoryId).toList();

      newState = newState.map((cat) {
        if (cat.children.any((child) => child.id == categoryId)) {
          return cat.copyWith(children: cat.children.where((child) => child.id != categoryId).toList());
        }
        return cat;
      }).toList();

      state = AsyncData(newState);
    } catch (e) {
      state = AsyncData(previousState);
      rethrow;
    }
  }
}
