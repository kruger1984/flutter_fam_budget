import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Змінили імпорт на наш справжній провайдер
import 'providers/payment_pod.dart';
import 'models/payable_product.dart';

class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Слухаємо наш PaymentController
    final state = ref.watch(paymentControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Преміум доступ'),
        centerTitle: true,
      ),
      body: SafeArea(
        // state.when автоматично обробляє 3 стани: завантаження, успіх, помилка
        child: state.when(
          data: (products) => _buildContent(context, ref, products),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Помилка завантаження підписок:\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<PayableProduct> products) {
    if (products.isEmpty) {
      return const Center(
        child: Text('Немає доступних підписок у вашому регіоні.'),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.star_rounded, size: 64, color: Colors.amber),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Відкрийте всі можливості!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),

        // Список доступних підписок
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final productDetails = products[index].productDetails;
              // final storeProduct = products[index].storeProduct; // Можна взяти дані з бекенду, якщо треба

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    // 🚀 ВИКЛИК ПОКУПКИ
                    ref.read(paymentControllerProvider.notifier).buyProduct(productDetails);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productDetails.title.replaceAll(RegExp(r'\(.*\)'), ''), // Прибираємо назву апки з тайтлу Apple
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                productDetails.description,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            productDetails.price, // Apple/Google самі дають відформатовану ціну
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Кнопка відновлення покупок
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextButton(
            onPressed: () {
              // 🚀 ВИКЛИК ВІДНОВЛЕННЯ
              ref.read(paymentControllerProvider.notifier).restorePurchases();
            },
            child: const Text('Відновити покупки', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}