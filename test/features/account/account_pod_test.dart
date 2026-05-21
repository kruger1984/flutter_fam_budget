import 'package:family_budget/features/account/models/account.dart';
import 'package:family_budget/features/account/models/currency.dart';
import 'package:family_budget/features/account/models/account_type.dart';
import 'package:family_budget/features/account/repository/account_repository.dart';
// Зміни цей імпорт на правильний шлях до твого майбутнього файлу провайдера
import 'package:family_budget/features/account/providers/account_pod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

void main() {
  late MockAccountRepository mockRepository;

  // Тестові дані
  final tAccountList = [
    Account(id: 1, name: 'Готівка', type: AccountType.cash, currency: Currency.uah, balance: 1000, isPersonal: true),
    Account(id: 2, name: 'Карта', type: AccountType.bank, currency: Currency.usd, balance: 50, isPersonal: false, familyId: 11),
  ];

  final tNewAccount = Account(id: 3, name: 'Скарбничка', type: AccountType.card, currency: Currency.uah, balance: 0, isPersonal: true);

  setUp(() {
    mockRepository = MockAccountRepository();
  });

  ProviderContainer makeProviderContainer() {
    final container = ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AccountsNotifier Tests', () {

    test('build() повинен завантажити список рахунків і повернути AsyncData', () async {
      // 1. ARRANGE
      // Кажемо репозиторію повернути наш заготовлений список
      when(() => mockRepository.getList()).thenAnswer((_) async => tAccountList);

      final container = makeProviderContainer();

      // 2. ACT
      // Читаємо провайдер (це автоматично запускає метод build)
      final state = await container.read(accountProvider.future);

      // 3. ASSERT
      // Перевіряємо, чи викликався репозиторій
      verify(() => mockRepository.getList()).called(1);

      // Перевіряємо, чи в стейті зараз наші 2 рахунки
      expect(state.length, 2);
      expect(state.first.name, 'Готівка');
    });

    test('createAccount() повинен викликати репозиторій і додати новий рахунок у список', () async {
      // 1. ARRANGE
      final container = makeProviderContainer();

      // Спочатку треба замокати getList для ініціалізації (build)
      when(() => mockRepository.getList()).thenAnswer((_) async => tAccountList);

      // Мокаємо успішне створення рахунку
      when(() => mockRepository.create(
        name: 'Скарбничка',
        type: AccountType.card,
        currency: Currency.uah,
        balance: 0,
      )).thenAnswer((_) async => tNewAccount);

      // Чекаємо, поки провайдер завантажить початкові дані
      await container.read(accountProvider.future);

      // 2. ACT
      // Викликаємо твій майбутній метод створення
      await container.read(accountProvider.notifier).createAccount(
        name: 'Скарбничка',
        type: AccountType.card,
        currency: Currency.uah,
        balance: 0,
      );

      // 3. ASSERT
      // Перевіряємо, чи репозиторій дійсно відправив дані на сервер
      verify(() => mockRepository.create(
        name: 'Скарбничка',
        type: AccountType.card,
        currency: Currency.uah,
        balance: 0,
      )).called(1);

      // Перевіряємо, чи список у стейті збільшився
      final state = container.read(accountProvider);
      expect(state.value?.length, 3); // Було 2, стало 3
      expect(state.value?.last.name, 'Скарбничка'); // Останній доданий — це наш новий рахунок
    });
  });
}