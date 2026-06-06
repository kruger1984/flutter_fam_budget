import 'package:family_budget/core/services/notification_service.dart';
import 'package:family_budget/core/utils/talker_pod.dart';
import 'package:family_budget/features/category/models/category.dart';
import 'package:family_budget/features/category/providers/category_pod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';

class CreateOrEditCategorySheet extends ConsumerStatefulWidget {
  final Category? category;

  const CreateOrEditCategorySheet({super.key, this.category});

  @override
  ConsumerState<CreateOrEditCategorySheet> createState() => _CreateOrEditCategorySheetState();
}

class _CreateOrEditCategorySheetState extends ConsumerState<CreateOrEditCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _isSubcategory = false;
  int? _selectedParentId;
  String? _selectedColor = '#2196F3';
  HeroIcons? _selectedIcon;
  bool _isLoading = false;

  final List<String> _colors = ['#FF5733', '#4CAF50', '#2196F3', '#FFC107', '#9C27B0', '#E91E63', '#607D8B'];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _isSubcategory = !widget.category!.isRoot;
      _selectedParentId = widget.category!.parentId;
      _selectedColor = widget.category!.color;
      _selectedIcon = widget.category!.icon;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isSubcategory && _selectedParentId == null) {
      ref.read(notificationServiceProvider).showError(context: context, title: 'Увага', description: 'Оберіть батьківську категорію');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final talker = ref.read(talkerProvider);
      if (widget.category == null) {
        talker.info('Creating new category: ${_nameController.text}');
        await ref.read(categoryProvider.notifier).createCategory(
              name: _nameController.text.trim(),
              icon: _selectedIcon,
              color: _isSubcategory ? null : _selectedColor,
              parentId: _isSubcategory ? _selectedParentId : null,
            );
      } else {
        talker.info('Updating category: ${widget.category!.id}');
        await ref.read(categoryProvider.notifier).updateCategory(
              id: widget.category!.id,
              name: _nameController.text.trim(),
              icon: _selectedIcon,
              color: _isSubcategory ? null : _selectedColor,
              parentId: _isSubcategory ? _selectedParentId : null,
            );
      }
      if (mounted) {
        ref.read(notificationServiceProvider).showSuccess(
              context: context,
              title: widget.category == null ? 'Категорію успішно створено!' : 'Категорію успішно оновлено!',
            );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider).showError(context: context, title: 'Помилка створення', description: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickIcon() async {
    final HeroIcons? pickedIcon = await showDialog<HeroIcons>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Виберіть іконку'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: HeroIcons.values.length,
              itemBuilder: (context, index) {
                final icon = HeroIcons.values[index];
                return InkWell(
                  onTap: () => Navigator.of(context).pop(icon),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: HeroIcon(icon, size: 24, color: Colors.blueGrey),
                  ),
                );
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Скасувати'))],
        );
      },
    );

    if (pickedIcon != null) {
      setState(() => _selectedIcon = pickedIcon);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rootCategories = ref.watch(categoryProvider).value?.where((c) => c.isRoot && !c.isSystem).toList() ?? [];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 24),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.category == null ? 'Нова категорія' : 'Редагувати',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Назва', border: OutlineInputBorder()),
                  validator: (val) => val != null && val.isEmpty ? 'Введіть назву' : null,
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                      child: _selectedIcon != null
                          ? HeroIcon(_selectedIcon!, size: 32, color: Colors.blueGrey)
                          : const Icon(Icons.category, size: 32, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickIcon,
                        icon: const Icon(Icons.touch_app),
                        label: Text(_selectedIcon == null ? 'Вибрати іконку' : 'Змінити іконку'),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      ),
                    ),
                    if (_selectedIcon != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => setState(() => _selectedIcon = null),
                        icon: const Icon(Icons.clear, color: Colors.red),
                        tooltip: 'Прибрати іконку',
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                SwitchListTile(
                  title: const Text('Це підкатегорія?'),
                  value: _isSubcategory,
                  onChanged: (val) => setState(() {
                    _isSubcategory = val;
                    if (val && rootCategories.isNotEmpty) {
                      // Перевіряємо, чи є поточний ID у відфільтрованому списку. Якщо ні - беремо перший.
                      if (!rootCategories.any((c) => c.id == _selectedParentId)) {
                        _selectedParentId = rootCategories.first.id;
                      }
                    } else if (val && rootCategories.isEmpty) {
                      // Якщо юзер хоче створити підкатегорію, але немає жодної ДОСТУПНОЇ батьківської
                      _isSubcategory = false;

                      ref.read(notificationServiceProvider).showError(context: context, title: 'Увага', description: 'Оберіть батьківську категорію');
                    }
                  }),
                  contentPadding: EdgeInsets.zero,
                ),

                if (_isSubcategory) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    key: ValueKey(_selectedParentId),
                    initialValue: _selectedParentId,
                    decoration: const InputDecoration(labelText: 'Батьківська категорія', border: OutlineInputBorder()),
                    items: rootCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (val) => setState(() => _selectedParentId = val),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  const Text('Колір:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: _colors.map((hexCode) {
                      final isSelected = _selectedColor == hexCode;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = hexCode),
                        child: CircleAvatar(
                          backgroundColor: Color(int.parse(hexCode.replaceFirst('#', '0xFF'))),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Зберегти', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
