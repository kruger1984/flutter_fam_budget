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
            title: Text(family.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                tooltip: 'Видалити сім\'ю з кешу (Тест)',
                onPressed: () {
                  // Викликаємо наш тестовий метод
                  ref.read(familyProvider.notifier).clearCacheForTest();
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  // Тут будуть налаштування сім'ї
                },
              ),
            ],
          ),
          body: Center(
            child: Text('Тут буде бюджет сім\'ї ${family.name}'),
          ),
        );
      },
    );
  }
}