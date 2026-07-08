import 'package:family_budget/features/category/models/app_icon.dart';
import 'package:family_budget/features/category/models/category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Category Model', () {
    test('повинен правильно парсити рекурсивний JSON (батько + діти)', () {
      // 1. ARRANGE: наш JSON, який імітує відповідь від Laravel
      final tCategoryRawJson = {
        'id': 1,
        'name': 'Транспорт',
        'icon': 'heroicon-o-shopping-cart',
        'color': '#FF5733',
        'parent_id': null,
        'children': [
          {
            'id': 11,
            'name': 'Паливо',
            'icon': 'fire',
            'color': '#FFC300',
            'parent_id': 1,
            'children': []
          },
        ]
      };

      // 2. ACT: викликаємо згенерований метод
      final category = Category.fromJson(tCategoryRawJson);

      // 3. ASSERT: перевіряємо, чи правильно зібралося "дерево"
      expect(category.id, 1);
      expect(category.parentId, isNull);

      // Перевіряємо дітей
      expect(category.children.length, 1);

      final child = category.children.first;
      expect(child.id, 11);
      expect(child.parentId, 1);
      expect(child.name, 'Паливо');
    });

    test('повинен парсити JSON, якщо icon == null (іконки може не бути)', () {
      final tCategoryRawJson = {
        'id': 1,
        'name': 'Без іконки',
        'icon': null,
        'color': '#FF5733',
        'parent_id': null,
        'children': []
      };

      final category = Category.fromJson(tCategoryRawJson);

      expect(category.id, 1);
      expect(category.icon, isNull);
    });

    test('повинен мапити невідому іконку на questionMarkCircle', () {
      final tCategoryRawJson = {
        'id': 1,
        'name': 'Невідома іконка',
        'icon': 'this-icon-does-not-exist',
        'color': '#FF5733',
        'parent_id': null,
        'children': []
      };

      final category = Category.fromJson(tCategoryRawJson);

      expect(category.icon, isNotNull);
      expect(category.icon, AppIcon.question);
    });
  });
}