import 'package:family_budget/shared/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Сьогодення';
      case 1:
        return 'Бюджет';
      case 2:
        return 'Цілі';
      case 3:
        return 'Навчання';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_getTitle(navigationShell.currentIndex)), centerTitle: true),
      drawer: SizedBox(width: MediaQuery.of(context).size.width, child: const AppDrawer()),
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Тут буде створення транзакції!')));
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.account_balance_wallet_outlined,
              activeIcon: Icons.account_balance_wallet,
              label: 'Головна',
              index: 0,
              currentIndex: navigationShell.currentIndex,
              onTap: () => _onTap(context, 0),
            ),
            _buildNavItem(
              icon: Icons.pie_chart_outline,
              activeIcon: Icons.pie_chart,
              label: 'Бюджет',
              index: 1,
              currentIndex: navigationShell.currentIndex,
              onTap: () => _onTap(context, 1),
            ),

            const SizedBox(width: 48),

            _buildNavItem(
              icon: Icons.track_changes_outlined,
              activeIcon: Icons.track_changes,
              label: 'Цілі',
              index: 2,
              currentIndex: navigationShell.currentIndex,
              onTap: () => _onTap(context, 2),
            ),
            _buildNavItem(
              icon: Icons.school_outlined,
              activeIcon: Icons.school,
              label: 'Навчання',
              index: 3,
              currentIndex: navigationShell.currentIndex,
              onTap: () => _onTap(context, 3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required int currentIndex,
    required VoidCallback onTap,
  }) {
    final isActive = index == currentIndex;
    final color = isActive ? Colors.blue : Colors.grey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}
