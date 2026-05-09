import 'package:family_budget/core/providers/bootstrap_providers.dart';
import 'package:family_budget/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/memory_auth_token_store.dart';
import 'package:family_budget/i18n/strings.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App shows sign in when logged out', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authTokenStoreProvider.overrideWithValue(MemoryAuthTokenStore()),
        ],
          child: TranslationProvider(
            child: const App(),
          ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Sign in'), findsWidgets);
  });
}
