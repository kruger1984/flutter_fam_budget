import 'package:family_budget/core/api/api_client.dart';
import 'package:family_budget/core/cache/app_cache.dart';
import 'package:family_budget/features/account/models/account.dart';
import 'package:family_budget/features/account/models/currency.dart';
import 'package:family_budget/features/account/models/account_type.dart';
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
    const userId = 1;
    final mockJsonResponse = {
      "success": true,
      "data": {
        "id": accountId,
        "name": name,
        "type": type.name,
        "currency": currency.name,
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
    final result = await repository.create(name: name, type: type, currency: currency, balance: balance, userId: userId);

    // ASSERT
    expect(result, isA<Account>());
    expect(result.id, accountId);
    expect(result.name, name);
    expect(result.currency, currency);
    expect(result.type, type);
  });

  test('getList() повинен правильно мапити список рахунків користувача і сім\'ї', () async {
    // 1. ARRANGE

    final familyId = 11;
    final userId = 1;
    final mockJsonResponse = {
      "success": true,
      "data": [
        {"id": 10, "name": 'my Account', "type": 'bank', "currency": 'usd', "balance": 0, "user_id": userId, "family_id": null, "is_personal": true},
        {"id": 20, "name": 'Family Account', "type": 'cash', "currency": 'uah', "balance": 0, "family_id": familyId, "is_personal": false},
      ],
    };

    when(() => mockCache.getRaw(namespace: 'auth', key: 'active_family_id'))
        .thenAnswer((_) async => familyId.toString());

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

  // test('getAccount(id) повинен повернути одну повноцінну модель сім\'ї', () async {
  //   // 1. ARRANGE
  //   const familyId = 10;
  //
  //   final mockJsonResponse = {
  //     "success": true,
  //     "data": {
  //       // Тут об'єкт, а не масив
  //       "id": familyId,
  //       "name": "My Own Family",
  //       "role": "owner",
  //       "owner": {"id": 1, "name": "Me", "email": "me@test.com"},
  //       "users": [
  //         {"id": 1, "name": "Me", "email": "me@test.com"},
  //         {"id": 2, "name": "Wife", "email": "wife@test.com"},
  //       ],
  //     },
  //   };
  //
  //   // Мокаємо запит до конкретного ID
  //   when(() => mockApi.get(path: 'families/$familyId')).thenAnswer((_) async => mockJsonResponse);
  //
  //   // 2. ACT
  //   final result = await repository.getFamily(familyId);
  //
  //   // 3. ASSERT
  //   expect(result, isA<Family>());
  //   expect(result.id, familyId);
  //   expect(result.users.length, 2);
  //   expect(result.owner.name, 'Me');
  // });
}
