import 'package:shared_preferences/shared_preferences.dart';

import 'app_cache.dart';

/// Non-sensitive cache backed by [SharedPreferences].
class PrefsAppCache extends AppCache {
  PrefsAppCache(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<Object?> getRaw({required String namespace, required String key}) async {
    final storageKey = CacheKey(namespace: namespace, key: key).toStorageKey();
    final encoded = _prefs.getString(storageKey);
    if (encoded == null) return null;

    final entry = CacheEntry.tryDecode(encoded);
    if (entry == null) {
      await _prefs.remove(storageKey);
      return null;
    }
    if (entry.isExpired) {
      await _prefs.remove(storageKey);
      return null;
    }
    return entry.value;
  }

  @override
  Future<void> putRaw({
    required String namespace,
    required String key,
    required Object? value,
    Duration? ttl,
    DateTime? expiresAt,
  }) async {
    final storageKey = CacheKey(namespace: namespace, key: key).toStorageKey();
    final entry = CacheEntry(value: value, expiresAtMs: computeExpiresAtMs(ttl: ttl, expiresAt: expiresAt));
    await _prefs.setString(storageKey, entry.encode());
  }

  @override
  Future<void> remove({required String namespace, required String key}) async {
    final storageKey = CacheKey(namespace: namespace, key: key).toStorageKey();
    await _prefs.remove(storageKey);
  }

  @override
  Future<void> clearNamespace(String namespace) async {
    final prefix = '$namespace::';
    final keys = _prefs.getKeys().where((k) => k.startsWith(prefix)).toList(growable: false);
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }
}

