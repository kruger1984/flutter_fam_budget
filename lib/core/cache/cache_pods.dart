import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bootstrap_providers.dart';
import 'file_app_cache.dart';
import 'prefs_app_cache.dart';
import 'secure_app_cache.dart';

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Non-sensitive app cache (SharedPreferences).
final appCacheProvider = Provider<PrefsAppCache>((ref) {
  return PrefsAppCache(ref.watch(sharedPreferencesProvider));
});

/// Disk cache (JSON files under app support directory).
final fileCacheProvider = Provider<FileAppCache>((ref) {
  return FileAppCache();
});

/// Sensitive cache (FlutterSecureStorage).
final secureCacheProvider = Provider<SecureAppCache>((ref) {
  return SecureAppCache(ref.watch(flutterSecureStorageProvider));
});

