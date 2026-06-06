import 'dart:convert';

import 'package:family_budget/core/api/api_client.dart';
import 'package:family_budget/core/api/http_pod.dart';
import 'package:family_budget/core/cache/app_cache.dart';
import 'package:family_budget/core/cache/cache_pods.dart';
import 'package:family_budget/core/utils/talker_pod.dart';
import 'package:family_budget/features/category/models/category.dart';
import 'package:heroicons/heroicons.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker/talker.dart';

import '../../../core/utils/hero_icon_converter.dart';

part 'category_repository.g.dart';

class CategoryRepository {
  CategoryRepository(this._api, this._talker, this._cache);

  final ApiClient _api;
  final Talker _talker;
  final AppCache _cache;

  Future<Category> create({required String name, HeroIcons? icon, String? color, int? parentId}) async {
    try {
      final response = await _api.post(path: 'categories', body: {
        'name': name,
        'icon': icon != null ? const HeroIconConverter().toJson(icon) : null,
        'color': color,
        'parent_id': parentId,
      });
      final Map<String, dynamic> data = response['data'];
      final familyId = await _cache.getRaw(namespace: 'auth', key: 'active_family_id');

      await _cache.remove(namespace: 'categories', key: 'family_$familyId');

      return Category.fromJson(data);
    } catch (e, st) {
      _talker.error('CategoryRepository: failed to create category', e, st);
      rethrow;
    }
  }

  Future<Category> update({required int id, required String name, HeroIcons? icon, String? color, int? parentId}) async {
    try {
      final requestData = <String, dynamic>{
        'name': name,
        'icon': icon != null ? const HeroIconConverter().toJson(icon) : null,
        'parent_id': parentId,
      };
      if (color != null) requestData['color'] = color;

      final response = await _api.put(path: 'categories/$id', data: requestData);

      final Map<String, dynamic> data = response['data'];
      final familyId = await _cache.getRaw(namespace: 'auth', key: 'active_family_id');
      await _cache.remove(namespace: 'categories', key: 'family_$familyId');

      return Category.fromJson(data);
    } catch (e, st) {
      _talker.error('CategoryRepository: failed to update category', e, st);
      rethrow;
    }
  }
  Future<List<Category>> getList() async {
    final familyId = await _cache.getRaw(namespace: 'auth', key: 'active_family_id');

    // 1. Пробуємо дістати з кешу
    final cachedRaw = await _cache.getRaw(namespace: 'categories', key: 'family_$familyId') as String?;

    if (cachedRaw != null) {
      try {
        final List<dynamic> cachedData = jsonDecode(cachedRaw);
        _talker.debug('🗂 Loaded categories from cache');
        return cachedData.map((model) => Category.fromJson(model as Map<String, dynamic>)).toList();
      } catch (e) {
        _talker.warning('CategoryRepository: cached data is corrupted');
      }
    }

    try {
      _talker.debug('🏠 request get categories from API');
      final response = await _api.get(path: 'categories');
      final List<dynamic> data = response['data'];

      await _cache.putRaw(namespace: 'categories', key: 'family_$familyId', value: jsonEncode(data), ttl: const Duration(hours: 24));

      return data.map((model) => Category.fromJson(model as Map<String, dynamic>)).toList();
    } catch (e, st) {
      _talker.error('CategoryRepository: failed to fetch categories', e, st);
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await _api.delete(path: 'categories/$id');
      final familyId = await _cache.getRaw(namespace: 'auth', key: 'active_family_id');
      await _cache.remove(namespace: 'categories', key: 'family_$familyId');
    } catch (e, st) {
      _talker.error('CategoryRepository: failed to delete categoryId: $id', e, st);
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(Ref ref) {
  return CategoryRepository(ref.watch(apiClientProvider), ref.watch(talkerProvider), ref.watch(appCacheProvider));
}
