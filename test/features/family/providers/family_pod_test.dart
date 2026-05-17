import 'package:family_budget/core/cache/app_cache.dart';
import 'package:family_budget/core/cache/cache_pods.dart';
import 'package:family_budget/features/auth/models/user.dart';
import 'package:family_budget/features/family/models/family.dart';
import 'package:family_budget/features/family/models/role.dart';
import 'package:family_budget/features/family/providers/family_pod.dart';
import 'package:family_budget/features/family/repository/family_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// 1. Мокаємо і Репозиторій, і Кеш
class MockFamilyRepository extends Mock implements FamilyRepository {}

class MockAppCache extends Mock implements AppCache {}

void main() {
  late MockFamilyRepository mockRepository;
  late MockAppCache mockCache;

  // Тестова сім'я, щоб не писати її кожен раз
  final tFamily = Family(
    id: 1,
    name: 'Test Family',
    role: Role.owner,
    owner: const User(id: 1, name: 'Admin', email: 'admin@test.com'),
    users: const [],
  );

  setUp(() {
    mockRepository = MockFamilyRepository();
    mockCache = MockAppCache();
  });

  // Зручна функція для створення контейнера з підміненими залежностями
  ProviderContainer makeProviderContainer() {
    final container = ProviderContainer(overrides: [familyRepositoryProvider.overrideWithValue(mockRepository), appCacheProvider.overrideWithValue(mockCache)]);
    addTearDown(container.dispose);
    return container;
  }

  group('FamilyNotifier', () {
    // Твій тест для створення сім'ї (трохи адаптований під makeProviderContainer)
    test('createFamily має змінити стан з Loading на Data', () async {
      final container = makeProviderContainer();

      when(() => mockRepository.create(any())).thenAnswer((_) async => tFamily);

      // Act
      await container.read(familyProvider.notifier).createFamily('New Family');

      // Assert
      final state = container.read(familyProvider);
      expect(state, isA<AsyncData<Family?>>());
      expect(state.value?.name, 'Test Family');

      // Перевіряємо, чи викликався метод репозиторію рівно 1 раз
      verify(() => mockRepository.create('New Family')).called(1);
    });

    test('switchFamily повинен зберігати ID в кеш і завантажувати сім\'ю', () async {
      final container = makeProviderContainer();

      // Мокаємо запис у кеш (він повертає Future<void>, тому пишемо так)
      when(() => mockCache.putRaw(namespace: 'auth', key: 'active_family_id', value: '1')).thenAnswer((_) async {});

      // Мокаємо отримання сім'ї
      when(() => mockRepository.getFamily(1)).thenAnswer((_) async => tFamily);

      // Act
      await container.read(familyProvider.notifier).switchFamily(1);

      // Assert
      // Перевіряємо, чи метод записав правильний ID у кеш
      verify(() => mockCache.putRaw(namespace: 'auth', key: 'active_family_id', value: '1')).called(1);

      // Перевіряємо, чи репозиторій зробив запит
      verify(() => mockRepository.getFamily(1)).called(1);

      // Перевіряємо, чи стан оновився
      final state = container.read(familyProvider);
      expect(state.value, equals(tFamily));
    });

    test('clearCacheForTest повинен видаляти ID з кешу і ставити state = null', () async {
      final container = makeProviderContainer();

      // Мокаємо видалення з кешу
      when(() => mockCache.remove(namespace: 'auth', key: 'active_family_id')).thenAnswer((_) async {});

      // Act
      await container.read(familyProvider.notifier).clearCacheForTest();

      // Assert
      verify(() => mockCache.remove(namespace: 'auth', key: 'active_family_id')).called(1);

      final state = container.read(familyProvider);
      expect(state.value, isNull);
    });
  });
}
