import 'package:family_budget/core/services/notification_service.dart';
import 'package:family_budget/core/utils/talker_pod.dart';
import 'package:family_budget/features/category/models/category.dart';
import 'package:family_budget/features/category/providers/category_pod.dart';
import 'package:family_budget/features/category/widgets/create_or_edit_category_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoryProvider);
    final talker = ref.read(talkerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Категорії'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSheet(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Додати'),
      ),
      body: categoriesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Помилка: $err')),
        data: (categories) {
          final rootCategoriesList = categories.where((c) => c.isRoot).toList();

          if (rootCategoriesList.isEmpty) {
            return const Center(child: Text('Категорій ще немає'));
          }

          return ListView.builder(
            itemCount: rootCategoriesList.length,
            itemBuilder: (context, index) {
              final rootCategory = rootCategoriesList[index];

              talker.debug(rootCategory);

              return Dismissible(
                key: ValueKey('root_${rootCategory.id}'),
                direction: rootCategory.isSystem ? DismissDirection.none : DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  color: Colors.red,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) => _confirmDelete(context, rootCategory.name),
                onDismissed: (_) => _deleteCategory(ref, context, rootCategory.id),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ExpansionTile(
                    leading: _buildIcon(rootCategory),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(rootCategory.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        if (!rootCategory.isSystem)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showSheet(context, rootCategory),
                          ),
                      ],
                    ),
                    trailing: rootCategory.children.isEmpty ? const SizedBox.shrink() : null,
                    children: rootCategory.children.map((subCategory) {
                      return Dismissible(
                        key: ValueKey('sub_${subCategory.id}'),
                        direction: subCategory.isSystem ? DismissDirection.none : DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) => _confirmDelete(context, subCategory.name),
                        onDismissed: (_) => _deleteCategory(ref, context, subCategory.id),
                        child: ListTile(
                          contentPadding: const EdgeInsets.only(left: 48, right: 16),
                          leading: _buildIcon(subCategory),
                          title: Text(subCategory.name),
                          trailing: subCategory.isSystem
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                                  onPressed: () => _showSheet(context, subCategory),
                                ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Видалити категорію?'),
        content: Text('Ви впевнені, що хочете видалити "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Скасувати')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(WidgetRef ref, BuildContext context, int id) async {
    try {
      await ref.read(categoryProvider.notifier).deleteCategory(id);
      if (context.mounted) {
        ref.read(notificationServiceProvider).showSuccess(context: context, title: 'Категорію видалено');
      }
    } catch (e) {
      if (context.mounted) {
        ref.read(notificationServiceProvider).showError(context: context, title: 'Помилка видалення', description: e.toString());
      }
    }
  }

  Widget _buildIcon(Category category) {


    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: category.color != null ? Color(int.parse(category.color!.replaceFirst('#', '0xFF'))).withValues(alpha: 0.2) : Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: category.icon != null
          ? HeroIcon(category.icon!.heroData, size: 24, color: category.color != null ? Color(int.parse(category.color!.replaceFirst('#', '0xFF'))) : Colors.grey)
          : const Icon(Icons.category, size: 24, color: Colors.grey),
    );
  }

  void _showSheet(BuildContext context, Category? category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => CreateOrEditCategorySheet(category: category),
    );
  }
}