import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:family_budget/core/api/api_client.dart';
import 'package:family_budget/core/api/api_exception.dart';
import 'package:family_budget/core/api/http_pod.dart';
import 'package:family_budget/core/cache/auth_token_store.dart';
import 'package:family_budget/core/providers/bootstrap_providers.dart';
import 'package:family_budget/core/utils/talker_pod.dart';
import 'package:family_budget/features/auth/models/auth_session.dart';
import 'package:family_budget/features/auth/models/user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:talker/talker.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  AuthRepository(this._api, this._talker, this._store);

  final ApiClient _api;
  final Talker _talker;
  final AuthTokenStore _store;

  static const _googleScopes = <String>['https://www.googleapis.com/auth/userinfo.profile', 'https://www.googleapis.com/auth/userinfo.email'];

  /// POST body matches common Laravel/Sanctum-style APIs; adjust path/body per backend.
  Future<AuthSession> login({required String email, required String password}) async {
    try {
      final raw = await _api.post(path: 'auth/login', body: {'email': email, 'password': password});
      final map = raw as Map<String, dynamic>;
      final token = map['token'] as String? ?? map['access_token'] as String?;
      if (token == null || token.isEmpty) {
        throw StateError('Login response has no token');
      }
      await _store.saveToken(token);

      Map<String, dynamic>? userJson;
      final user = map['user'];
      if (user is Map<String, dynamic>) userJson = user;
      final item = map['item'];
      if (userJson == null && item is Map<String, dynamic>) userJson = item;

      final appUser = userJson != null ? AppUser.fromJson(userJson) : null;
      return AuthSession(token: token, user: appUser);
    } on ApiException catch (e, st) {
      _talker.error('Login failed', e, st);
      rethrow;
    }
  }

  /// Google sign-in → backend token exchange → [AuthSession].
  Future<AuthSession> loginWithGoogle() async {
    try {
      _talker.info('AuthRepository: Google sign-in started');

      final googleSignIn = GoogleSignIn(scopes: _googleScopes);
      final account = await googleSignIn.signIn();
      if (account == null) {
        throw ApiException('Google sign-in canceled', 0);
      }

      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        throw ApiException('Google access token is empty', 0);
      }

      return loginWithSocialToken(provider: 'google', token: accessToken);
    } on ApiException {
      rethrow;
    } catch (e, st) {
      _talker.error('Google sign-in failed', e, st);
      throw ApiException(e.toString(), 0);
    }
  }

  /// Apple sign-in → backend token exchange → [AuthSession].
  Future<AuthSession> loginWithApple() async {
    try {
      _talker.info('AuthRepository: Apple sign-in started');

      final rawNonce = _generateNonce();
      final nonce = _sha256OfString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: nonce,
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw ApiException('Apple identity token is empty', 0);
      }

      return loginWithSocialToken(provider: 'apple', token: identityToken);
    } on SignInWithAppleAuthorizationException catch (e, st) {
      _talker.error('Apple sign-in failed', e, st);
      if (e.code == AuthorizationErrorCode.canceled) {
        throw ApiException('Apple sign-in canceled', 0);
      }
      throw ApiException(e.message, 0);
    } on ApiException {
      rethrow;
    } catch (e, st) {
      _talker.error('Apple sign-in failed', e, st);
      throw ApiException(e.toString(), 0);
    }
  }

  /// Common helper: exchange provider token for app token, persist, and load user.
  Future<AuthSession> loginWithSocialToken({required String provider, required String token}) async {
    try {
      _talker.info('AuthRepository: loginWithSocialToken started (provider=$provider)');

      // Legacy-compatible endpoint; adjust path/query if your backend differs.
      final raw = await _api.get(path: 'social-auth/$provider/callback', queryParameters: <String, dynamic>{'provider': provider, 'token': token});

      final map = raw as Map<String, dynamic>;
      final appToken = map['token'] as String?;
      if (appToken == null || appToken.isEmpty) {
        throw ApiException('Social login response has no token', 0);
      }

      await _store.saveToken(appToken);

      // Optionally load user profile so UI gets user immediately.
      try {
        final profileRaw = await _api.get(path: 'profile');
        final profileMap = profileRaw as Map<String, dynamic>;
        final item = profileMap['item'] ?? profileMap['user'] ?? profileMap['data'];
        final user = item is Map<String, dynamic> ? AppUser.fromJson(item) : null;
        return AuthSession(token: appToken, user: user);
      } catch (e, st) {
        _talker.warning('Failed to load profile after social login: $e');
        _talker.handle(e, st, 'profile after social login');
        return AuthSession(token: appToken, user: null);
      }
    } on ApiException {
      rethrow;
    } catch (e, st) {
      _talker.error('Social login failed (provider=$provider)', e, st);
      throw ApiException(e.toString(), 0);
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256OfString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<AuthSession?> restoreSession() async {
    final token = await _store.readToken();
    if (token == null || token.isEmpty) return null;
    try {
      final raw = await _api.get(path: 'profile');
      final map = raw as Map<String, dynamic>;
      final item = map['item'] ?? map['user'] ?? map['data'];
      if (item is! Map<String, dynamic>) {
        return AuthSession(token: token, user: null);
      }
      return AuthSession(token: token, user: AppUser.fromJson(item));
    } on ApiException catch (e) {
      if (e.code == 401) {
        await _store.clearToken();
        return null;
      }
      _talker.warning('Profile fetch failed during restore: $e');
      return AuthSession(token: token, user: null);
    } catch (e, st) {
      _talker.handle(e, st, 'restoreSession');
      await _store.clearToken();
      return null;
    }
  }

  Future<void> logout() async {
    await _store.clearToken();
  }

  Future<AppUser> getUser() async {
    try {
      final raw = await _api.get(path: 'profile');
      final map = raw as Map<String, dynamic>;
      final item = map['item'] ?? map['user'] ?? map['data'];

      if (item is Map<String, dynamic>) {
        return AppUser.fromJson(item);
      }
      throw ApiException('Неправильний формат даних профілю', 0);
    } catch (e, st) {
      _talker.error('Помилка отримання профілю', e, st);
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.watch(apiClientProvider), ref.watch(talkerProvider), ref.watch(authTokenStoreProvider));
}
