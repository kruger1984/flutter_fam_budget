import 'package:family_budget/core/utils/talker_pod.dart';
import 'package:family_budget/features/category/models/app_icon.dart';
import 'package:family_budget/features/category/models/category.dart';
import 'package:family_budget/features/category/providers/category_pod.dart';
import 'package:family_budget/features/category/repository/category_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockCategoryRepository mockRepository;

  final tRootCategory = Category(id: 1, name: 'Транспорт', icon: AppIcon.truck, color: '#000', parentId: null, children: []);
  final tSubCategory = Category(id: 2, name: 'Паливо', icon: AppIcon.shoppingCart, color: '#000', parentId: 1, children: []);

  setUp(() {
    mockRepository = MockCategoryRepository();
  });

  ProviderContainer makeProviderContainer() {
    final silentTalker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    final container = ProviderContainer(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(mockRepository),
        talkerProvider.overrideWithValue(silentTalker),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('CategoryNotifier Tests', () {
    test('build() повинен завантажити список категорій', () async {
      when(() => mockRepository.getList()).thenAnswer((_) async => [tRootCategory]);
      final container = makeProviderContainer();

      final state = await container.read(categoryProvider.future);

      expect(state.length, 1);
      expect(state.first.name, 'Транспорт');
      verify(() => mockRepository.getList()).called(1);
    });

    test('createCategory() [Головна] додає категорію в корінь списку', () async {
      final container = makeProviderContainer();
      when(() => mockRepository.getList()).thenAnswer((_) async => []);

      final newRoot = Category(id: 3, name: 'Їжа', icon: AppIcon.shoppingCart, color: '#fff', parentId: null, children: []);
      when(() => mockRepository.create(name: 'Їжа', icon: AppIcon.shoppingCart, color: '#fff', parentId: null))
          .thenAnswer((_) async => newRoot);

      await container.read(categoryProvider.future);
      await container.read(categoryProvider.notifier).createCategory(name: 'Їжа', icon: AppIcon.shoppingCart, color: '#fff', parentId: null);

      final state = container.read(categoryProvider).value!;
      expect(state.length, 1);
      expect(state.first.name, 'Їжа');
    });

    test('createCategory() [Підкатегорія] додає категорію в children батька', () async {
      final container = makeProviderContainer();
      // Початковий стан: є лише головна категорія (Транспорт, id: 1)
      when(() => mockRepository.getList()).thenAnswer((_) async => [tRootCategory]);

      // Створюємо підкатегорію (Паливо, parentId: 1)
      // Важливо: в UI для підкатегорії color відправляється як null (колір наслідується на бекенді).
      when(() => mockRepository.create(name: 'Паливо', icon: AppIcon.home, color: null, parentId: 1))
          .thenAnswer((_) async => tSubCategory);

      await container.read(categoryProvider.future);
      await container.read(categoryProvider.notifier).createCategory(name: 'Паливо', icon: AppIcon.home, color: null, parentId: 1);

      final state = container.read(categoryProvider).value!;

      // Перевіряємо, що головна категорія залишилась одна, але у неї з'явилась дитина
      expect(state.length, 1);
      expect(state.first.children.length, 1);
      expect(state.first.children.first.name, 'Паливо');
    });

    test('createCategory() відкачує state і пробросує помилку, якщо репозиторій кидає exception', () async {
      final container = makeProviderContainer();
      when(() => mockRepository.getList()).thenAnswer((_) async => [tRootCategory]);
      when(() => mockRepository.create(name: any(named: 'name'), icon: any(named: 'icon'), color: any(named: 'color'), parentId: any(named: 'parentId')))
          .thenThrow(Exception('API Error'));

      await container.read(categoryProvider.future);

      final previousState = container.read(categoryProvider).value!;

      expect(
        () => container.read(categoryProvider.notifier).createCategory(name: 'Їжа', icon: AppIcon.shoppingCart, color: '#fff', parentId: null),
        throwsException,
      );

      final stateAfter = container.read(categoryProvider).value!;
      expect(stateAfter, previousState);
    });

    test('deleteCategory() видаляє підкатегорію локально', () async {
      final container = makeProviderContainer();
      // Початковий стан: Транспорт має всередині Паливо
      final rootWithChild = tRootCategory.copyWith(children: [tSubCategory]);
      when(() => mockRepository.getList()).thenAnswer((_) async => [rootWithChild]);
      when(() => mockRepository.delete(2)).thenAnswer((_) async => Future.value());

      await container.read(categoryProvider.future);

      // Видаляємо підкатегорію (id: 2)
      await container.read(categoryProvider.notifier).deleteCategory(2);

      final state = container.read(categoryProvider).value!;

      // Головна залишилась, але список children став порожнім
      expect(state.length, 1);
      expect(state.first.id, 1);
      expect(state.first.children, isEmpty);
    });

    test('deleteCategory() відкачує state і пробросує помилку, якщо репозиторій кидає exception', () async {
      final container = makeProviderContainer();
      when(() => mockRepository.getList()).thenAnswer((_) async => [tRootCategory]);
      when(() => mockRepository.delete(1)).thenThrow(Exception('API Error'));

      await container.read(categoryProvider.future);

      final previousState = container.read(categoryProvider).value!;

      expect(() => container.read(categoryProvider.notifier).deleteCategory(1), throwsException);

      final stateAfter = container.read(categoryProvider).value!;
      expect(stateAfter, previousState);
    });
  });
}