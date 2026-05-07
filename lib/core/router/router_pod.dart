import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/home_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/payment/payment_screen.dart';
import '../../features/payment/thanks_screen.dart';

part 'router_pod.g.dart';

@riverpod
GoRouter router(Ref ref) {

  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final session = authState.asData?.value;

      final isLoggingIn = state.matchedLocation == '/login';

      if (authState.isLoading) return null;

      if (session == null) {

        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        return '/';
      }

      return null;
    },

    routes: [

      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),


      GoRoute(
        path: '/',
        builder: (context, state) {
          return authState.when(
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Scaffold(
              body: Center(child: Text('Error: $e')),
            ),
            data: (session) {
              if (session == null) {
                return const SizedBox();
              }
              return AuthHomeScreen(session: session);
            },
          );
        },
      ),

      /* Add new routers here:
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      */
      GoRoute(path: '/payment', builder: (context, state) => const PaymentScreen()),

      GoRoute(
        path: '/payment/thanks',
        builder: (context, state) {
          final message = state.extra as String? ?? 'Дякуємо за покупку!';
          return ThanksScreen(message: message);
        },
      ),
    ],

    errorBuilder: (context, state) => Scaffold(body: Center(child: Text('Сторінку не знайдено: ${state.error}'))),
  );
}
