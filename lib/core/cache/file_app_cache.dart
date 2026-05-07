import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_cache.dart';

/// Disk-backed cache (JSON files) stored under the app support directory.
///
/// Behavior matches the old `Cache` class semantics:
/// - each namespace has its own folder
/// - each key is a separate json file
/// - expired/broken entries are deleted on read
/// - oversized payloads are silently skipped
class FileAppCache extends AppCache {
  FileAppCache({
    String rootFolderName = 'cache',
    int maxEntryBytes = 5 * 1024 * 1024,
  })  : _rootFolderName = rootFolderName,
        _maxEntryBytes = maxEntryBytes;

  final String _rootFolderName;
  final int _maxEntryBytes;

  Future<Directory> _getNamespaceDir(String namespace) async {
    final baseDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(baseDir.path, _rootFolderName, 'cache_$namespace'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _fileNameFor({required String namespace, required String key}) {
    // Make filename filesystem-safe and stable.
    final keyEncoded = base64UrlEncode(utf8.encode(key));
    return '1__${namespace}__$keyEncoded.json';
  }

  Future<File> _getFile({required String namespace, required String key}) async {
    final dir = await _getNamespaceDir(namespace);
    return File(p.join(dir.path, _fileNameFor(namespace: namespace, key: key)));
  }

  @override
  Future<Object?> getRaw({required String namespace, required String key}) async {
    final file = await _getFile(namespace: namespace, key: key);
    if (!await file.exists()) return null;

    try {
      final encoded = await file.readAsString();
      final entry = CacheEntry.tryDecode(encoded);
      if (entry == null || entry.isExpired) {
        try {
          await file.delete();
        } catch (_) {}
        return null;
      }
      return entry.value;
    } catch (_) {
      try {
        await file.delete();
      } catch (_) {}
      return null;
    }
  }

  @override
  Future<void> putRaw({
    required String namespace,
    required String key,
    required Object? value,
    Duration? ttl,
    DateTime? expiresAt,
  }) async {
    final file = await _getFile(namespace: namespace, key: key);
    final entry = CacheEntry(value: value, expiresAtMs: computeExpiresAtMs(ttl: ttl, expiresAt: expiresAt));
    final encoded = entry.encode();

    if (encoded.length > _maxEntryBytes) {
      return;
    }

    await file.writeAsString(encoded, flush: true);
  }

  @override
  Future<void> remove({required String namespace, required String key}) async {
    final file = await _getFile(namespace: namespace, key: key);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  @override
  Future<void> clearNamespace(String namespace) async {
    final dir = await _getNamespaceDir(namespace);
    if (!await dir.exists()) return;

    await for (final entity in dir.list()) {
      if (entity is File) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }
}

