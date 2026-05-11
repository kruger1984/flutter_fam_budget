import 'package:family_budget/features/auth/models/user.dart';
import 'package:family_budget/features/family/models/family.dart';
import 'package:family_budget/features/family/models/role.dart';
import 'package:family_budget/features/family/providers/family_pod.dart';
import 'package:family_budget/features/family/repository/family_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';


class MockFamilyRepository extends Mock implements FamilyRepository {}

void main() {
  late MockFamilyRepository mockRepository;

  setUp(() {
    mockRepository = MockFamilyRepository();
  });

  test('FamilyNotifier при створенні сім\'ї має змінити стан з Loading на Data', () async {
    final container = ProviderContainer(
      overrides: [
        familyRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );

    final family = Family(
      id: 1,
      name: 'Test Family',
      role: Role.owner,
      owner: const User(id: 1, name: 'Admin'),
      users: const [],
    );

    // Мокаємо успішне створення
    when(() => mockRepository.create(any())).thenAnswer((_) async => family);

    // Act
    await container.read(familyProvider.notifier).createFamily('New Family');

    // Assert
    final state = container.read(familyProvider);
    expect(state, isA<AsyncData<Family?>>());
    expect(state.value?.name, 'Test Family');
  });
}