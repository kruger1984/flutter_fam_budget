import 'dart:async';

import 'package:family_budget/core/providers/bootstrap_providers.dart';
import 'package:family_budget/core/router/router_pod.dart';
import 'package:family_budget/core/utils/talker_pod.dart';
import 'package:family_budget/shared/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'i18n/strings.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); // Activate if need Analytics

  final prefs = await SharedPreferences.getInstance();

  LocaleSettings.useDeviceLocale();

  runApp(ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)], child: TranslationProvider(child: const App())));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final talker = ref.watch(talkerProvider);
    final router = ref.watch(routerProvider);

    return TalkerWrapper(
      talker: talker,
      child: MaterialApp.router(
        title: 'Family Budget',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: router,

        // --- Localization Setup ---
        locale: TranslationProvider.of(context).flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
  }
}
