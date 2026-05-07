import 'package:family_budget/core/cache/secure_app_cache.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the bearer token. Used by [DioFactory] and auth repository.
abstract class AuthTokenStore {
  Future<String?> readToken();

  Future<void> saveToken(String token);

  Future<void> clearToken();
}

/// Production store backed by [FlutterSecureStorage].
class SecureAuthTokenStore implements AuthTokenStore {
  SecureAuthTokenStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _namespace = 'auth';
  static const _key = 'token';

  @override
  Future<void> clearToken() async {
    final cache = SecureAppCache(_storage);
    await cache.remove(namespace: _namespace, key: _key);
  }

  @override
  Future<String?> readToken() async {
    final cache = SecureAppCache(_storage);
    final raw = await cache.getRaw(namespace: _namespace, key: _key);
    if (raw is String) return raw;
    return raw?.toString();
  }

  @override
  Future<void> saveToken(String token) async {
    final cache = SecureAppCache(_storage);
    await cache.putRaw(namespace: _namespace, key: _key, value: token);
  }
}
