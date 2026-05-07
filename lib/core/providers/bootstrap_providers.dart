import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cache/auth_token_store.dart';

/// Initialized in [main] via [ProviderScope] override (see ARCHITECTURE.md).
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnsupportedError('sharedPreferencesProvider must be overridden in main()');
});

/// Override in tests with an in-memory [AuthTokenStore].
final authTokenStoreProvider = Provider<AuthTokenStore>((ref) {
  return SecureAuthTokenStore();
});
