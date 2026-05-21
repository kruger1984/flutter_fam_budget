import 'package:family_budget/shared/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../family/providers/family_pod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyState = ref.watch(familyProvider);

    return familyState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(body: Center(child: Text('Помилка: $error'))),
      data: (family) {
        if (family == null) return const SizedBox.shrink();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Сьогодення'),
            centerTitle: true,
          ),

          drawer: const AppDrawer(),

          body: const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Мої рахунки',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  // TODO: Тут буде список рахунків з accountNotifierProvider
                  Expanded(
                    child: Center(
                      child: Text('Тут будуть картки рахунків'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}