import 'package:family_budget/core/cache/auth_token_store.dart';

/// In-memory [AuthTokenStore] for tests (no platform secure storage).
class MemoryAuthTokenStore implements AuthTokenStore {
  String? _token;

  @override
  Future<void> clearToken() async {
    _token = null;
  }

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }
}
