import 'package:family_budget/core/api/api_client.dart';
import 'package:family_budget/core/cache/app_cache.dart';
import 'package:family_budget/features/account/models/account.dart';
import 'package:family_budget/features/account/models/account_type.dart';
import 'package:family_budget/features/account/models/currency.dart';
import 'package:family_budget/features/account/repository/account_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockTalker extends Mock implements Talker {}

class MockAppCache extends Mock implements AppCache {}

void main() {
  late AccountRepository repository;
  late MockApiClient mockApi;
  late MockAppCache mockCache;
  late MockTalker mockTalker;

  setUp(() {
    mockApi = MockApiClient();
    mockCache = MockAppCache();
    mockTalker = MockTalker();
    repository = AccountRepository(mockApi, mockTalker, mockCache);

    when(
      () => mockCache.getRaw(
        namespace: any(named: 'namespace'),
        key: any(named: 'key'),
      ),
    ).thenAnswer((_) async => null);

    when(
      () => mockCache.remove(
        namespace: any(named: 'namespace'),
        key: any(named: 'key'),
      ),
    ).thenAnswer((_) async => {});

    when(
      () => mockCache.putRaw(
        namespace: any(named: 'namespace'),
        key: any(named: 'key'),
        value: any(named: 'value'),
        ttl: any(named: 'ttl'),
      ),
    ).thenAnswer((_) async => {});
  });

  test('create() повинен повернути Account при успішному створенні (201)', () async {
    // ARRANGE
    const accountId = 1;
    const name = 'Сімейний рахунок грн';
    const type = AccountType.cash;
    const currency = Currency.uah;
    const balance = 0;
    // const userId = 1;
    final mockJsonResponse = {
      "success": true,
      "data": {
        "id": accountId,
        "name": name,
        "type": type.name,
        "currency": currency.name.toUpperCase(),
        "balance": balance,
        "user_id": 1,
        "family_id": null,
        "is_personal": true,
      },
    };

    when(
      () => mockApi.post(
        path: 'accounts',
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => mockJsonResponse);

    // ACT
    final result = await repository.create(name: name, type: type, currency: currency, balance: balance, isPersonal: true);

    // ASSERT
    expect(result, isA<Account>());
    expect(result.id, accountId);
    expect(result.name, name);
    expect(result.currency, currency);
    expect(result.type, type);
  });

  test('update() повинен відправити PUT запит та повернути оновлений Account', () async {
    // 1. ARRANGE
    const accountId = 1;
    const updatedName = 'Оновлена Зарплатна Картка';
    const updatedType = AccountType.card;
    const existingBalance = 5000;
    const existingCurrency = Currency.uah;

    // Імітуємо відповідь сервера після оновлення
    final mockJsonResponse = {
      "success": true,
      "data": {
        "id": accountId,
        "name": updatedName,
        "type": updatedType.name,
        "currency": existingCurrency.name.toUpperCase(),
        "balance": existingBalance,
        "user_id": 1,
        "family_id": null,
        "is_personal": true,
      },
    };

    when(
      () => mockApi.put(
        path: 'accounts/$accountId',
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => mockJsonResponse);

    // 2. ACT
    // Викликаємо оновлення. Валюту НЕ передаємо!
    final result = await repository.update(id: accountId, name: updatedName, type: updatedType);

    // 3. ASSERT
    expect(result, isA<Account>());
    expect(result.id, accountId);
    expect(result.name, updatedName);
    expect(result.type, updatedType);
    expect(result.balance, existingBalance);
    expect(result.currency, existingCurrency);

    verify(
      () => mockApi.put(
        path: 'accounts/$accountId',
        data: any(named: 'data'),
      ),
    ).called(1);
  });

  test('getList() повинен правильно мапити список рахунків користувача і сім\'ї', () async {
    // 1. ARRANGE

    final familyId = 11;
    final userId = 1;
    final mockJsonResponse = {
      "success": true,
      "data": [
        {"id": 10, "name": 'my Account', "type": 'bank', "currency": 'USD', "balance": 0, "user_id": userId, "family_id": null, "is_personal": true},
        {"id": 20, "name": 'Family Account', "type": 'cash', "currency": 'UAH', "balance": 0, "family_id": familyId, "is_personal": false},
      ],
    };

    when(() => mockCache.getRaw(namespace: 'auth', key: 'active_family_id')).thenAnswer((_) async => familyId.toString());

    when(() => mockApi.get(path: 'accounts')).thenAnswer((_) async => mockJsonResponse);
    when(
      () => mockCache.putRaw(
        namespace: any(named: 'namespace'),
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async => Future.value());

    // 2. ACT
    final result = await repository.getList();

    // 3. ASSERT
    expect(result.length, 2);

    // Перевіряємо першу сім'ю (де ти власник)
    expect(result[0].id, 10);
    expect(result[0].type, AccountType.bank);
    expect(result[0].currency, Currency.usd);
    expect(result[0].isPersonal, true);

    // Перевіряємо другу сім'ю (де ти член)
    expect(result[1].id, 20);
    expect(result[1].type, AccountType.cash);
    expect(result[1].isPersonal, false);

    verify(
      () => mockCache.putRaw(
        namespace: 'accounts',
        key: 'user_accounts_family_$familyId',
        value: any(named: 'value'),
        ttl: any(named: 'ttl'),
      ),
    ).called(1);
  });

  test('delete() повинен відправити DELETE запит на правильний шлях', () async {
    // 1. ARRANGE
    const accountId = 1;

    // Використовуємо any(named: 'path'), щоб мок не падав через зайвий слеш
    // Laravel response()->noContent() повертає пусту відповідь, тому імітуємо повернення null
    when(() => mockApi.delete(path: any(named: 'path'))).thenAnswer((_) async => null);

    // 2. ACT
    await repository.delete(accountId);

    // 3. ASSERT
    // А тут ми перевіряємо, чи дійсно шлях містить 'accounts/1'.
    // Підстав сюди точний рядок з твого AccountRepository (зі слешем чи без)
    verify(
      () => mockApi.delete(path: 'accounts/$accountId'), // Якщо падає тут — зміни на '/accounts/$accountId'
    ).called(1);
  });
}
