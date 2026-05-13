import 'package:family_budget/features/family/family_gate_screen.dart';
import 'package:family_budget/features/family/providers/family_pod.dart';
import 'package:family_budget/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/payment/payment_screen.dart';
import '../../features/payment/thanks_screen.dart';

part 'router_pod.g.dart';

@riverpod
GoRouter router(Ref ref) {
  final authState = ref.watch(authProvider);
  final familyState = ref.watch(familyProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final isAtGate = state.matchedLocation == '/gate';
      final isPayment = state.matchedLocation.startsWith('/payment');

      if (authState.isLoading) return null;

      final session = authState.asData?.value;

      if (session == null) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) return '/';

      if (familyState.isLoading) return null;

      final family = familyState.asData?.value;

      if (family == null) {
        return (isAtGate || isPayment) ? null : '/gate';
      }

      if (isAtGate) {
        return '/';
      }

      return null;
    },

    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      GoRoute(path: '/gate', builder: (context, state) => const FamilyGateScreen()),

      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),

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
