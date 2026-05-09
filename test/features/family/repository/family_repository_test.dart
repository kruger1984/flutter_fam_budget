import 'package:family_budget/core/api/api_client.dart';
import 'package:family_budget/core/cache/app_cache.dart';
import 'package:family_budget/features/family/models/family.dart';
import 'package:family_budget/features/family/repository/family_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockAppCache extends Mock implements AppCache {}

void main() {
  late FamilyRepository repository;
  late MockApiClient mockApi;
  late MockAppCache mockCache;
  late Talker talker;

  setUp(() {
    mockApi = MockApiClient();
    mockCache = MockAppCache();
    talker = Talker();
    repository = FamilyRepository(mockApi, talker, mockCache);
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
}
