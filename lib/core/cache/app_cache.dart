import 'dart:convert';
import 'dart:async';

/// A reusable cache service with namespace isolation and TTL support.
///
/// Repositories decide what to cache; this interface only provides primitives.
abstract class AppCache {
  Future<Object?> getRaw({
    required String namespace,
    required String key,
  });

  Future<void> putRaw({
    required String namespace,
    required String key,
    required Object? value,
    Duration? ttl,
    DateTime? expiresAt,
  });

  Future<void> remove({
    required String namespace,
    required String key,
  });

  Future<void> clearNamespace(String namespace);

  Future<T?> getJson<T>({
    required String namespace,
    required String key,
    required T Function(Object? json) fromJson,
  }) async {
    final raw = await getRaw(namespace: namespace, key: key);
    if (raw == null) return null;
    return fromJson(raw);
  }

  Future<void> putJson({
    required String namespace,
    required String key,
    required Object? json,
    Duration? ttl,
    DateTime? expiresAt,
  }) {
    return putRaw(
      namespace: namespace,
      key: key,
      value: json,
      ttl: ttl,
      expiresAt: expiresAt,
    );
  }

  Future<T> rememberJson<T>({
    required String namespace,
    required String key,
    required T Function(Object? json) fromJson,
    required Future<Object?> Function() fetchJson,
    Duration? ttl,
    DateTime? expiresAt,
  }) async {
    final cached = await getJson<T>(
      namespace: namespace,
      key: key,
      fromJson: fromJson,
    );
    if (cached != null) return cached;

    final json = await fetchJson();
    await putJson(
      namespace: namespace,
      key: key,
      json: json,
      ttl: ttl,
      expiresAt: expiresAt,
    );
    return fromJson(json);
  }

  /// Cache a computed value, supporting both sync and async callbacks.
  ///
  /// Mirrors the old `Cache.remember(...)` behavior.
  Future<Object?> rememberRaw({
    required String namespace,
    required String key,
    required FutureOr<Object?> Function() compute,
    Duration? ttl,
    DateTime? expiresAt,
  }) async {
    final cached = await getRaw(namespace: namespace, key: key);
    if (cached != null) return cached;

    final value = await Future<Object?>.value(compute());
    await putRaw(
      namespace: namespace,
      key: key,
      value: value,
      ttl: ttl,
      expiresAt: expiresAt,
    );
    return value;
  }
}

class CacheKey {
  CacheKey({required this.namespace, required this.key});

  final String namespace;
  final String key;

  String toStorageKey() => '$namespace::$key';
}

class CacheEntry {
  CacheEntry({required this.value, this.expiresAtMs});

  final Object? value;
  final int? expiresAtMs;

  bool get isExpired {
    final exp = expiresAtMs;
    if (exp == null) return false;
    return DateTime.now().millisecondsSinceEpoch >= exp;
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'expires_at_ms': expiresAtMs,
        'value': value,
      };

  String encode() => jsonEncode(toJson());

  static CacheEntry? tryDecode(String encoded) {
    try {
      final obj = jsonDecode(encoded);
      if (obj is! Map) return null;
      return CacheEntry(
        value: obj['value'],
        expiresAtMs: obj['expires_at_ms'] is int ? obj['expires_at_ms'] as int : null,
      );
    } catch (_) {
      return null;
    }
  }
}

int? computeExpiresAtMs({Duration? ttl, DateTime? expiresAt}) {
  if (expiresAt != null) return expiresAt.millisecondsSinceEpoch;
  if (ttl != null) {
    return DateTime.now().add(ttl).millisecondsSinceEpoch;
  }
  return null;
}

