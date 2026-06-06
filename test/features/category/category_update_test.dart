import 'package:family_budget/core/api/api_client.dart';
import 'package:family_budget/core/cache/app_cache.dart';
import 'package:family_budget/core/utils/talker_pod.dart';
import 'package:family_budget/features/category/models/category.dart';
import 'package:family_budget/features/category/providers/category_pod.dart';
import 'package:family_budget/features/category/repository/category_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heroicons/heroicons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockTalker extends Mock implements Talker {}

class MockAppCache extends Mock implements AppCache {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  group('CategoryRepository.update()', () {
    late CategoryRepository repository;
    late MockApiClient mockApi;
    late MockAppCache mockCache;
    late MockTalker mockTalker;

    setUp(() {
      mockApi = MockApiClient();
      mockCache = MockAppCache();
      mockTalker = MockTalker();
      repository = CategoryRepository(mockApi, mockTalker, mockCache);

      when(
        () => mockCache.getRaw(
          namespace: any(named: 'namespace'),
          key: any(named: 'key'),
        ),
      ).thenAnswer((_) async => '11');

      when(
        () => mockCache.remove(
          namespace: any(named: 'namespace'),
          key: any(named: 'key'),
        ),
      ).thenAnswer((_) async {});
    });

    test('відправляє PUT для root і інвалідує кеш', () async {
      const categoryId = 1;
      const updatedName = 'Оновлений транспорт';
      const updatedColor = '#4CAF50';

      final mockJsonResponse = {
        'success': true,
        'data': {'id': categoryId, 'name': updatedName, 'icon': 'truck', 'color': updatedColor, 'parent_id': null, 'children': []},
      };

      when(
        () => mockApi.put(
          path: 'categories/$categoryId',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => mockJsonResponse);

      final result = await repository.update(id: categoryId, name: updatedName, icon: HeroIcons.truck, color: updatedColor);

      expect(result.id, categoryId);
      expect(result.name, updatedName);
      expect(result.color, updatedColor);
      expect(result.parentId, isNull);

      verify(() => mockApi.put(
        path: 'categories/$categoryId',
        data: {
          'name': updatedName,
          'icon': 'truck',
          'color': updatedColor,
          'parent_id': null,
        },
      )).called(1);
      verify(() => mockCache.remove(namespace: 'categories', key: 'family_11')).called(1);
    });

    test('для підкатегорії не відправляє color (наслідується на бекенді)', () async {
      const categoryId = 2;
      const updatedName = 'Оновлене паливо';

      final mockJsonResponse = {
        'success': true,
        'data': {'id': categoryId, 'name': updatedName, 'icon': 'fire', 'color': null, 'parent_id': 1, 'children': []},
      };

      when(
        () => mockApi.put(
          path: 'categories/$categoryId',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => mockJsonResponse);

      final result = await repository.update(id: categoryId, name: updatedName, icon: HeroIcons.fire, color: null);

      expect(result.id, categoryId);
      expect(result.name, updatedName);
      expect(result.parentId, 1);

      final captured =
          verify(
                () => mockApi.put(
                  path: 'categories/$categoryId',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as Map<String, dynamic>;

      expect(captured['name'], updatedName);
      expect(captured['icon'], 'fire');
      expect(captured.containsKey('color'), isFalse);
    });

    test('дозволяє icon == null (іконки може не бути)', () async {
      const categoryId = 1;
      const updatedName = 'Без іконки';

      final mockJsonResponse = {
        'success': true,
        'data': {'id': categoryId, 'name': updatedName, 'icon': null, 'color': '#2196F3', 'parent_id': null, 'children': []},
      };

      when(
        () => mockApi.put(
          path: 'categories/$categoryId',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => mockJsonResponse);

      final result = await repository.update(id: categoryId, name: updatedName, icon: null, color: '#2196F3');

      expect(result.icon, isNull);

      verify(() => mockApi.put(
        path: 'categories/$categoryId',
        data: {
          'name': updatedName,
          'icon': null,
          'color': '#2196F3',
          'parent_id': null,
        },
      )).called(1);
    });
  });

  group('CategoryNotifier.updateCategory()', () {
    late MockCategoryRepository mockRepository;

    final tRootCategory = Category(id: 1, name: 'Транспорт', icon: HeroIcons.truck, color: '#000', parentId: null, children: []);

    final tSubCategory = Category(id: 2, name: 'Паливо', icon: HeroIcons.fire, color: null, parentId: 1, children: []);

    setUp(() {
      mockRepository = MockCategoryRepository();
    });

    ProviderContainer makeProviderContainer() {
      final silentTalker = Talker(settings: TalkerSettings(useConsoleLogs: false));
      final container = ProviderContainer(
        overrides: [categoryRepositoryProvider.overrideWithValue(mockRepository), talkerProvider.overrideWithValue(silentTalker)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('[Root] оновлює головну категорію і зберігає children', () async {
      final container = makeProviderContainer();
      final child = tSubCategory.copyWith(name: 'Старе паливо');
      final rootWithChild = tRootCategory.copyWith(children: [child]);

      when(() => mockRepository.getList()).thenAnswer((_) async => [rootWithChild]);

      const updatedName = 'Авто';
      const updatedColor = '#4CAF50';
      final apiResponse = tRootCategory.copyWith(name: updatedName, color: updatedColor, children: []);

      when(() => mockRepository.update(
            id: 1,
            name: updatedName,
            icon: HeroIcons.truck,
            color: updatedColor,
            parentId: any(named: 'parentId'),
          )).thenAnswer((_) async => apiResponse);

      await container.read(categoryProvider.future);
      await container.read(categoryProvider.notifier).updateCategory(id: 1, name: updatedName, icon: HeroIcons.truck, color: updatedColor);

      final state = container.read(categoryProvider).value!;

      expect(state.length, 1);
      expect(state.first.name, updatedName);
      expect(state.first.color, updatedColor);
      expect(state.first.children.length, 1);
      expect(state.first.children.first.name, 'Старе паливо');

      verify(() => mockRepository.update(
            id: 1,
            name: updatedName,
            icon: HeroIcons.truck,
            color: updatedColor,
            parentId: any(named: 'parentId'),
          )).called(1);
    });

    test('[Підкатегорія] оновлює child і викликає update з color: null', () async {
      final container = makeProviderContainer();
      final rootWithChild = tRootCategory.copyWith(children: [tSubCategory]);

      when(() => mockRepository.getList()).thenAnswer((_) async => [rootWithChild]);

      const updatedName = 'Бензин';
      final apiResponse = tSubCategory.copyWith(name: updatedName, icon: null);

      when(() => mockRepository.update(
            id: 2,
            name: updatedName,
            icon: null,
            color: null,
            parentId: any(named: 'parentId'),
          )).thenAnswer((_) async => apiResponse);

      await container.read(categoryProvider.future);
      await container.read(categoryProvider.notifier).updateCategory(id: 2, name: updatedName, icon: null, color: null);

      final state = container.read(categoryProvider).value!;
      final updatedChild = state.first.children.first;

      expect(state.length, 1);
      expect(updatedChild.name, updatedName);
      expect(updatedChild.icon, isNull);

      verify(() => mockRepository.update(
            id: 2,
            name: updatedName,
            icon: null,
            color: null,
            parentId: any(named: 'parentId'),
          )).called(1);
    });

    test('відкачує state і пробросує помилку, якщо update кидає exception', () async {
      final container = makeProviderContainer();
      when(() => mockRepository.getList()).thenAnswer((_) async => [tRootCategory]);
      when(
        () => mockRepository.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          icon: any(named: 'icon'),
          color: any(named: 'color'),
          parentId: any(named: 'parentId'),
        ),
      ).thenThrow(Exception('API Error'));

      await container.read(categoryProvider.future);
      final previousState = container.read(categoryProvider).value!;

      expect(() => container.read(categoryProvider.notifier).updateCategory(id: 1, name: 'Помилка', icon: HeroIcons.truck, color: '#000'), throwsException);

      expect(container.read(categoryProvider).value, previousState);
    });
  });
}
