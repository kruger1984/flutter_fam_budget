import 'package:dio/dio.dart';
import 'package:family_budget/core/api/api_client.dart';
import 'package:family_budget/core/cache/app_cache.dart';
import 'package:family_budget/features/family/models/famil_exception.dart';
import 'package:family_budget/features/family/models/family.dart';
import 'package:family_budget/features/family/models/role.dart';
import 'package:family_budget/features/family/repository/family_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockTalker extends Mock implements Talker {}

class MockAppCache extends Mock implements AppCache {}

void main() {
  late FamilyRepository repository;
  late MockApiClient mockApi;
  late MockAppCache mockCache;
  late MockTalker mockTalker;

  setUp(() {
    mockApi = MockApiClient();
    mockCache = MockAppCache();
    mockTalker = MockTalker();
    repository = FamilyRepository(mockApi, mockTalker, mockCache);

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

  test('create() повинен повернути Family при успішному створенні (201)', () async {
    // ARRANGE
    const familyId = 1;
    const familyName = 'Kovalenko Family';
    final mockJsonResponse = {
      "success": true,
      "data": {
        "id": 1,
        "name": familyName,
        "role": "owner",
        "owner": {"id": 1, "name": "Admin"},
        "users": [],
      },
    };

    when(
      () => mockApi.post(
        path: 'families',
        body: any(named: 'body'),
      ),
    ).thenAnswer((_) async => mockJsonResponse);

    when(
      () => mockCache.putRaw(
        namespace: any(named: 'namespace'),
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async => Future.value());

    // ACT
    final result = await repository.create(familyName);

    // ASSERT
    expect(result, isA<Family>());
    expect(result.id, familyId);
    expect(result.name, familyName);

    verify(() => mockCache.putRaw(namespace: 'auth', key: 'active_family_id', value: familyId.toString())).called(1);
  });

  test('getList() повинен правильно мапити список сімей з різними ролями', () async {
    // 1. ARRANGE
    final mockJsonResponse = {
      "success": true,
      "data": [
        {
          "id": 10,
          "name": "My Own Family",
          "role": "owner", // Ти власник
          "owner": {"id": 1, "name": "Me"},
          "users": [],
        },
        {
          "id": 20,
          "name": "Friend's Family",
          "role": "member", // Ти просто учасник
          "owner": {"id": 99, "name": "John Doe"},
          "users": [],
        },
      ],
    };

    when(() => mockApi.get(path: 'families')).thenAnswer((_) async => mockJsonResponse);

    // 2. ACT
    final result = await repository.getList();

    // 3. ASSERT
    expect(result.length, 2);

    // Перевіряємо першу сім'ю (де ти власник)
    expect(result[0].id, 10);
    expect(result[0].role, Role.owner);

    // Перевіряємо другу сім'ю (де ти член)
    expect(result[1].id, 20);
    expect(result[1].role, Role.member);
    expect(result[1].owner.name, 'John Doe');
  });

  test('join() повинен створити модель Family з API та зберегти ID в кеш', () async {
    // 1. ARRANGE
    const inviteCode = 'ABC-123';
    const joinedFamilyId = 55;

    final mockJsonResponse = {
      "success": true,
      "data": {
        "id": joinedFamilyId,
        "name": "New Family",
        "role": "member",
        "owner": {"id": 1, "name": "Admin"},
        "users": [],
      },
    };

    when(() => mockApi.post(path: 'families/join', body: {'code': inviteCode})).thenAnswer((_) async => mockJsonResponse);

    when(
      () => mockCache.putRaw(
        namespace: any(named: 'namespace'),
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async => Future.value());

    // 2. ACT
    final result = await repository.join(inviteCode);

    // 3. ASSERT (Перевіряємо дані моделі)
    expect(result, isA<Family>()); // Ось ми перевіряємо, що модель СТВОРИЛАСЯ
    expect(result.id, joinedFamilyId);
    expect(result.role, Role.member);

    // 4. VERIFY (Перевіряємо побічну дію)
    verify(() => mockCache.putRaw(namespace: 'auth', key: 'active_family_id', value: joinedFamilyId.toString())).called(1);
  });

  test('join() має викинути InvalidInviteCodeException при 410', () async {
    const inviteCode = 'WRONG-CODE';

    final dioError = DioException(
      requestOptions: RequestOptions(path: 'families/join'),
      response: Response(
        requestOptions: RequestOptions(path: 'families/join'),
        statusCode: 410,
        data: {'message': 'Invalid code'},
      ),
      type: DioExceptionType.badResponse,
    );

    when(
      () => mockApi.post(
        path: 'families/join',
        body: any(named: 'body'),
      ),
    ).thenThrow(dioError);

    expect(() => repository.join(inviteCode), throwsA(isA<InvalidInviteCodeException>()));

    // Перевіряємо, що логер все одно отримав виклик (необов'язково, але можна)
    verifyNever(() => mockTalker.error(any(), any(), any())).called(0);
  });

  test('getFamily(id) повинен повернути одну повноцінну модель сім\'ї', () async {
    // 1. ARRANGE
    const familyId = 10;

    final mockJsonResponse = {
      "success": true,
      "data": {
        // Тут об'єкт, а не масив
        "id": familyId,
        "name": "My Own Family",
        "role": "owner",
        "owner": {"id": 1, "name": "Me", "email": "me@test.com"},
        "users": [
          {"id": 1, "name": "Me", "email": "me@test.com"},
          {"id": 2, "name": "Wife", "email": "wife@test.com"},
        ],
      },
    };

    // Мокаємо запит до конкретного ID
    when(() => mockApi.get(path: 'families/$familyId')).thenAnswer((_) async => mockJsonResponse);

    // 2. ACT
    final result = await repository.getFamily(familyId);

    // 3. ASSERT
    expect(result, isA<Family>());
    expect(result.id, familyId);
    expect(result.users.length, 2);
    expect(result.owner.name, 'Me');
  });
}
