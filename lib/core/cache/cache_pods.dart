import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bootstrap_providers.dart';
// Переконайся, що імпортуєш файл з інтерфейсом AppCache, якщо він лежить окремо
import 'app_cache.dart';
import 'file_app_cache.dart';
import 'prefs_app_cache.dart';
import 'secure_app_cache.dart';

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final appCacheProvider = Provider<AppCache>((ref) {
  return PrefsAppCache(ref.watch(sharedPreferencesProvider));
});

final fileCacheProvider = Provider<AppCache>((ref) {
  return FileAppCache();
});

final secureCacheProvider = Provider<AppCache>((ref) {
  return SecureAppCache(ref.watch(flutterSecureStorageProvider));
});