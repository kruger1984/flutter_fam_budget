import 'dart:convert';
import 'package:family_budget/core/api/api_client.dart';
import 'package:family_budget/core/cache/app_cache.dart';
import 'package:family_budget/features/category/models/app_icon.dart';
import 'package:family_budget/features/category/models/category.dart';
import 'package:family_budget/features/category/repository/category_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockTalker extends Mock implements Talker {}
class MockAppCache extends Mock implements AppCache {}

void main() {
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
          () => mockCache.getRaw(namespace: any(named: 'namespace'), key: any(named: 'key')),
    ).thenAnswer((_) async => null);

    when(
          () => mockCache.remove(namespace: any(named: 'namespace'), key: any(named: 'key')),
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

  group('CategoryRepository Tests', () {
    test('create() повинен відправити POST запит і повернути Category', () async {
      final mockJsonResponse = {
        "success": true,
        "data": {
          "id": 1,
          "name": "Нова категорія",
          "icon": "star",
          "color": "#FFFFFF",
          "parent_id": null,
          "children": []
        },
      };

      when(() => mockApi.post(path: 'categories', body: any<dynamic>(named: 'body')))
          .thenAnswer((_) async => mockJsonResponse);
      when(() => mockCache.getRaw(namespace: 'auth', key: 'active_family_id'))
          .thenAnswer((_) async => '11');

      final result = await repository.create(
        name: 'Нова категорія',
        icon: AppIcon.shoppingCart,
        color: '#FFFFFF',
        parentId: null,
      );

      expect(result, isA<Category>());
      expect(result.id, 1);
      expect(result.name, 'Нова категорія');

      verify(() => mockApi.post(path: 'categories', body: any<dynamic>(named: 'body'))).called(1);
      verify(() => mockCache.remove(namespace: 'categories', key: 'family_11')).called(1);
    });

    test('getList() повинен завантажити з API, якщо кеш пустий, і зберегти в кеш', () async {
      final familyId = '11';
      final mockJsonResponse = {
        "success": true,
        "data": [
          {"id": 1, "name": "Транспорт", "icon": "truck", "color": "#000000", "parent_id": null, "children": []}
        ],
      };

      when(() => mockCache.getRaw(namespace: 'auth', key: 'active_family_id'))
          .thenAnswer((_) async => familyId);
      when(() => mockCache.getRaw(namespace: 'categories', key: 'family_$familyId'))
          .thenAnswer((_) async => null); // Кеш пустий
      when(() => mockApi.get(path: 'categories'))
          .thenAnswer((_) async => mockJsonResponse);

      final result = await repository.getList();

      expect(result.length, 1);
      expect(result.first.name, 'Транспорт');
      verify(() => mockApi.get(path: 'categories')).called(1);
      verify(() => mockCache.putRaw(
        namespace: 'categories',
        key: 'family_$familyId',
        value: any(named: 'value'),
        ttl: any(named: 'ttl'),
      )).called(1); // Перевіряємо, що дані записалися в кеш
    });

    test('getList() повинен повернути дані з кешу і НЕ викликати API', () async {
      final familyId = '11';
      final cachedJsonString = jsonEncode([
        {"id": 1, "name": "Транспорт з кешу", "icon": "truck", "color": "#000000", "parent_id": null, "children": []}
      ]);

      when(() => mockCache.getRaw(namespace: 'auth', key: 'active_family_id'))
          .thenAnswer((_) async => familyId);
      // Імітуємо, що кеш Є
      when(() => mockCache.getRaw(namespace: 'categories', key: 'family_$familyId'))
          .thenAnswer((_) async => cachedJsonString);

      final result = await repository.getList();

      expect(result.length, 1);
      expect(result.first.name, 'Транспорт з кешу');
      verifyNever(() => mockApi.get(path: any(named: 'path'))); // АПІ НЕ викликалось!
    });

    test('getList() повинен піти в API, якщо кеш зламаний (невалідний JSON)', () async {
      final familyId = '11';
      final brokenCachedValue = '{not-valid-json';
      final mockJsonResponse = {
        "success": true,
        "data": [
          {"id": 1, "name": "Транспорт", "icon": "truck", "color": "#000000", "parent_id": null, "children": []}
        ],
      };

      when(() => mockCache.getRaw(namespace: 'auth', key: 'active_family_id'))
          .thenAnswer((_) async => familyId);
      when(() => mockCache.getRaw(namespace: 'categories', key: 'family_$familyId'))
          .thenAnswer((_) async => brokenCachedValue);
      when(() => mockApi.get(path: 'categories'))
          .thenAnswer((_) async => mockJsonResponse);

      final result = await repository.getList();

      expect(result.length, 1);
      expect(result.first.name, 'Транспорт');
      verify(() => mockApi.get(path: 'categories')).called(1);
      verify(() => mockCache.putRaw(
        namespace: 'categories',
        key: 'family_$familyId',
        value: any(named: 'value'),
        ttl: any(named: 'ttl'),
      )).called(1);
    });

    test('delete() повинен відправити DELETE запит', () async {
      when(() => mockApi.delete(path: any(named: 'path')))
          .thenAnswer((_) async => null);
      when(() => mockCache.getRaw(namespace: 'auth', key: 'active_family_id'))
          .thenAnswer((_) async => '11');

      await repository.delete(1);

      verify(() => mockApi.delete(path: 'categories/1')).called(1);
      verify(() => mockCache.remove(namespace: 'categories', key: 'family_11')).called(1);
    });
  });
}