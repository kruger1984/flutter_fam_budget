import 'package:family_budget/core/api/api_client.dart';
import 'package:family_budget/core/cache/app_cache.dart';
import 'package:family_budget/features/account/models/currency.dart';
import 'package:family_budget/features/transaction/models/transaction.dart';
import 'package:family_budget/features/transaction/models/transaction_type.dart';
import 'package:family_budget/features/transaction/repository/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockTalker extends Mock implements Talker {}

class MockAppCache extends Mock implements AppCache {}

void main() {
  late TransactionRepository repository;
  late MockApiClient mockApi;
  late MockAppCache mockCache;
  late MockTalker mockTalker;

  const familyId = 11;

  setUp(() {
    mockApi = MockApiClient();
    mockCache = MockAppCache();
    mockTalker = MockTalker();
    repository = TransactionRepository(mockApi, mockTalker, mockCache);

    registerFallbackValue(const Duration(minutes: 10));

    // Default setup to avoid Null errors if mock called without specific when
    when(
      () => mockCache.getRaw(
        namespace: any(named: 'namespace'),
        key: any(named: 'key'),
      ),
    ).thenAnswer((_) async => null);

    when(() => mockCache.getRaw(namespace: 'auth', key: 'active_family_id')).thenAnswer((_) async => familyId.toString());

    when(
      () => mockCache.remove(
        namespace: any(named: 'namespace'),
        key: any(named: 'key'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockCache.putRaw(
        namespace: any(named: 'namespace'),
        key: any(named: 'key'),
        value: any(named: 'value'),
        ttl: any(named: 'ttl'),
      ),
    ).thenAnswer((_) async {});
  });

  group('TransactionRepository Tests', () {
    test('getList() повинен завантажити дані з API та зберегти в кеш', () async {
      final mockJsonResponse = {
        "success": true,
        "data": [
          {
            "id": 101,
            "user_id": 1,
            "account_id": 1,
            "target_account_id": null,
            "category_id": 5,
            "type": "expense",
            "amount": 50000,
            "currency": "UAH",
            "target_amount": null,
            "target_currency": null,
            "exchange_rate": null,
            "description": "Вечеря",
            "created_at": "2023-10-27T10:00:00Z",
          },
          {
            "id": 102,
            "account_id": 1,
            "user_id": 1,
            "target_account_id": 2,
            "category_id": null,
            "type": "transfer",
            "amount": 1000,
            "currency": "USD",
            "target_amount": 41000,
            "target_currency": "UAH",
            "exchange_rate": 41.0,
            "description": "Обмін",
            "created_at": "2023-10-27T11:00:00Z",
          },
        ],
      };

      when(() => mockApi.get(path: 'transactions')).thenAnswer((_) async => mockJsonResponse);

      final result = await repository.getList();

      expect(result.length, 2);
      expect(result[0].type, TransactionType.expense);
      expect(result[1].type, TransactionType.transfer);
      expect(result[1].targetAmount, 41000);

      verify(() => mockApi.get(path: 'transactions')).called(1);
      verify(
        () => mockCache.putRaw(
          namespace: 'transactions',
          key: 'family_$familyId',
          value: any(named: 'value'),
          ttl: any(named: 'ttl'),
        ),
      ).called(1);
    });

    test('create() повинен відправити POST запит та очистити кеш', () async {
      final mockJsonResponse = {
        "success": true,
        "data": {
          "id": 103,
          "account_id": 1,
          "user_id": 1,
          "target_account_id": null,
          "category_id": 10,
          "type": "expense",
          "amount": 20000,
          "currency": "UAH",
          "target_amount": null,
          "target_currency": null,
          "exchange_rate": null,
          "description": "Нова витрата",
          "created_at": "2023-10-27T12:00:00Z",
        },
      };

      when(
        () => mockApi.post(
          path: 'transactions',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => mockJsonResponse);

      final result = await repository.create(
        type: TransactionType.expense,
        amount: 20000,
        accountId: 1,
        categoryId: 10,
        currency: Currency.uah,
        description: 'Нова витрата',
      );

      expect(result.id, 103);
      verify(
        () => mockApi.post(
          path: 'transactions',
          body: any(named: 'body'),
        ),
      ).called(1);
      verify(() => mockCache.remove(namespace: 'transactions', key: 'family_$familyId')).called(1);
      verify(() => mockCache.remove(namespace: 'accounts', key: 'user_accounts_family_$familyId')).called(1);
    });

    test('update() повинен відправити PUT запит та очистити точковий кеш', () async {
      final mockJsonResponse = {
        "success": true,
        "data": {
          "id": 103,
          "account_id": 1,
          "user_id": 1,
          "target_account_id": 2, // Це переказ
          "category_id": null,
          "type": "transfer",
          "amount": 20000,
          "currency": "UAH",
          "target_amount": 500,
          "target_currency": "USD",
          "exchange_rate": 40.0,
          "description": "Оновлений переказ",
          "created_at": "2023-10-27T12:00:00Z",
        },
      };

      when(
        () => mockApi.put(
          path: 'transactions/103',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => mockJsonResponse);

      final result = await repository.update(
        id: 103,
        type: TransactionType.transfer,
        amount: 20000,
        accountId: 1,
        targetAccountId: 2,
        targetAmount: 500,
        currency: Currency.uah,
        targetCurrency: Currency.usd,
        description: 'Оновлений переказ',
      );

      expect(result.id, 103);
      expect(result.description, 'Оновлений переказ');

      verify(
        () => mockApi.put(
          path: 'transactions/103',
          data: any(named: 'data'),
        ),
      ).called(1);

      // Перевіряємо, що очистився і загальний кеш, і кеш обох рахунків
      verify(() => mockCache.remove(namespace: 'transactions', key: 'family_$familyId')).called(1);
      verify(() => mockCache.remove(namespace: 'accounts', key: 'user_accounts_family_$familyId')).called(1);
      verify(() => mockCache.remove(namespace: 'transactions', key: 'account_1')).called(1);
      verify(() => mockCache.remove(namespace: 'transactions', key: 'account_2')).called(1);
    });

    test('getListByAccount() повинен завантажити дані для одного рахунку', () async {
      final mockJsonResponse = {
        "success": true,
        "data": [
          {"id": 101,"user_id": 1, "account_id": 1, "type": "expense", "amount": 50000, "currency": "UAH"},
        ],
      };

      when(() => mockApi.get(path: 'transactions?account=1')).thenAnswer((_) async => mockJsonResponse);

      final result = await repository.getListByAccount(1);

      expect(result.length, 1);
      expect(result.first.accountId, 1);

      verify(() => mockApi.get(path: 'transactions?account=1')).called(1);
      verify(
        () => mockCache.putRaw(
          namespace: 'transactions',
          key: 'account_1',
          value: any(named: 'value'),
          ttl: any(named: 'ttl'),
        ),
      ).called(1);
    });

    test('delete() повинен відправити DELETE запит та очистити правильний кеш', () async {
      when(() => mockApi.delete(path: any(named: 'path'))).thenAnswer((_) async => null);

      const tTransaction = Transaction(id: 101,userId: 1, accountId: 1, type: TransactionType.expense, amount: 50000, currency: Currency.uah);

      await repository.delete(tTransaction);

      verify(() => mockApi.delete(path: 'transactions/101')).called(1);

      verify(() => mockCache.remove(namespace: 'transactions', key: 'family_$familyId')).called(1);
      verify(() => mockCache.remove(namespace: 'accounts', key: 'user_accounts_family_$familyId')).called(1);
      verify(() => mockCache.remove(namespace: 'transactions', key: 'account_1')).called(1);

      verifyNever(() => mockCache.remove(namespace: 'transactions', key: 'account_null'));
    });
  });
}
