import 'package:family_budget/core/services/notification_service.dart';
import 'package:family_budget/features/family/providers/family_pod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/famil_exception.dart';

class FamilyGateScreen extends ConsumerStatefulWidget {
  const FamilyGateScreen({super.key});

  @override
  ConsumerState<FamilyGateScreen> createState() => _FamilyGateScreenState();
}

class _FamilyGateScreenState extends ConsumerState<FamilyGateScreen> {
  final _createController = TextEditingController();
  final _joinController = TextEditingController();
  int? _selectedFamilyId;

  @override
  void dispose() {
    _createController.dispose();
    _joinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyProvider);

    final familiesListState = ref.watch(userFamiliesListProvider);

    ref.listen(familyProvider, (previous, next) {
      if (next is AsyncError) {
        final error = next.error;
        String message = 'Щось пішло не так';

        if (error is InvalidInviteCodeException) {
          message = 'Код недійсний або його термін дії вийшов';
        } else if (error is AlreadyInFamilyException) {
          message = 'Ти вже є в цій сім\'ї';
        } else if (error is UnknownFamilyException) {
          message = error.message;
        }

        ref.read(notificationServiceProvider).showError(context: context, title: 'Помилка', description: message);
      }

      if (next is AsyncData && next.value != null && previous is AsyncLoading) {
        // Можна також показати успіх
        ref.read(notificationServiceProvider).showSuccess(context: context, title: 'Успішно', description: 'Ви приєдналися до сім\'ї');
      }
    });

    final isLoading = familyState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Твоя сім\'я'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            familiesListState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Помилка завантаження списку: $e'),
              data: (families) {
                if (families.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Вибери існуючу сім\'ю',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.list)),
                      hint: const Text('Обери сім\'ю...'),
                      initialValue: _selectedFamilyId,
                      items: families.map((family) {
                        return DropdownMenuItem<int>(value: family.id, child: Text('${family.name} (${family.role.name})'));
                      }).toList(),
                      onChanged: isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _selectedFamilyId = value;
                              });
                            },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: (_selectedFamilyId == null || isLoading)
                          ? null
                          : () {
                              ref.read(familyProvider.notifier).switchFamily(_selectedFamilyId!);
                            },
                      child: const Text('Перейти'),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),

            const Text(
              'Створи нову сім\'ю або приєднайся до існуючої',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            TextField(
              controller: _createController,
              decoration: const InputDecoration(labelText: 'Назва нової сім\'ї', border: OutlineInputBorder(), prefixIcon: Icon(Icons.home)),
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      final name = _createController.text.trim();
                      if (name.isNotEmpty) {
                        ref.read(familyProvider.notifier).createFamily(name);
                      }
                    },
              child: const Text('Створити'),
            ),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 40),

            // --- БЛОК ПРИЄДНАННЯ ---
            TextField(
              controller: _joinController,
              decoration: const InputDecoration(
                labelText: 'Код запрошення',
                hintText: 'Наприклад: FMB-9X2A',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      final code = _joinController.text.trim();
                      if (code.isNotEmpty) {
                        ref.read(familyProvider.notifier).joinFamily(code);
                      }
                    },
              child: const Text('Приєднатися'),
            ),

            // Показуємо лоадер, коли йде запит
            if (isLoading) ...[const SizedBox(height: 24), const Center(child: CircularProgressIndicator())],
          ],
        ),
      ),
    );
  }
}
