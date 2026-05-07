import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_cache.dart';

/// Sensitive cache backed by [FlutterSecureStorage].
class SecureAppCache extends AppCache {
  SecureAppCache(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<Object?> getRaw({required String namespace, required String key}) async {
    final storageKey = CacheKey(namespace: namespace, key: key).toStorageKey();
    final encoded = await _storage.read(key: storageKey);
    if (encoded == null) return null;

    final entry = CacheEntry.tryDecode(encoded);
    if (entry == null) {
      await _storage.delete(key: storageKey);
      return null;
    }
    if (entry.isExpired) {
      await _storage.delete(key: storageKey);
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
    await _storage.write(key: storageKey, value: entry.encode());
  }

  @override
  Future<void> remove({required String namespace, required String key}) async {
    final storageKey = CacheKey(namespace: namespace, key: key).toStorageKey();
    await _storage.delete(key: storageKey);
  }

  @override
  Future<void> clearNamespace(String namespace) async {
    final prefix = '$namespace::';
    final all = await _storage.readAll();
    for (final k in all.keys) {
      if (k.startsWith(prefix)) {
        await _storage.delete(key: k);
      }
    }
  }
}

