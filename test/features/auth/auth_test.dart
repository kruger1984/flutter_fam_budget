import 'package:dio/dio.dart';
import 'package:family_budget/core/api/api_client.dart';
import 'package:family_budget/core/api/http_pod.dart';
import 'package:family_budget/core/providers/bootstrap_providers.dart';
import 'package:family_budget/core/utils/talker_pod.dart';
import 'package:family_budget/features/auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/memory_auth_token_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('login persists token and updates auth state', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = MemoryAuthTokenStore();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/'));
    DioAdapter(dio: dio, matcher: const UrlRequestMatcher(matchMethod: true))
      .onPost('auth/login', (server) {
        return server.reply(200, {
          'token': 't1',
          'user': {'id': '1', 'email': 'a@b.com'},
        });
      });

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authTokenStoreProvider.overrideWithValue(store),
        apiClientProvider.overrideWith((ref) {
          return ApiClient(dio, talker: ref.watch(talkerProvider));
        }),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authProvider.notifier).login(email: 'a@b.com', password: 'secret');
    final session = await container.read(authProvider.future);

    expect(session?.token, 't1');
    expect(session?.user?.email, 'a@b.com');
    expect(await store.readToken(), 't1');
  });

  test('logout clears token and session', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = MemoryAuthTokenStore();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/'));
    DioAdapter(dio: dio, matcher: const UrlRequestMatcher(matchMethod: true))
      .onPost('auth/login', (server) {
        return server.reply(200, {'token': 'tok'});
      });

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authTokenStoreProvider.overrideWithValue(store),
        apiClientProvider.overrideWith((ref) {
          return ApiClient(dio, talker: ref.watch(talkerProvider));
        }),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authProvider.notifier).login(email: 'a@b.c', password: 'p');
    await container.read(authProvider.notifier).logout();
    final session = await container.read(authProvider.future);
    expect(session, isNull);
    expect(await store.readToken(), isNull);
  });

  test('restoreSession loads profile when token exists', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = MemoryAuthTokenStore();
    await store.saveToken('existing');

    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/'));
    DioAdapter(dio: dio, matcher: const UrlRequestMatcher(matchMethod: true))
      .onGet('profile', (server) {
        return server.reply(200, {
          'item': {'id': '42', 'email': 'restored@example.com'},
        });
      });

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authTokenStoreProvider.overrideWithValue(store),
        apiClientProvider.overrideWith((ref) {
          return ApiClient(dio, talker: ref.watch(talkerProvider));
        }),
      ],
    );
    addTearDown(container.dispose);

    final session = await container.read(authProvider.future);
    expect(session?.token, 'existing');
    expect(session?.user?.id, 42);
    expect(session?.user?.email, 'restored@example.com');
  });
}
