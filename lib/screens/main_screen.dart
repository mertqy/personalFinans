import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_screen.dart';
import 'statistics_screen.dart';
import 'payments_screen.dart';
import 'budget_screen.dart';
import '../widgets/transaction_modal.dart';

import '../providers/navigation_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final PageController _pageController = PageController();

  // Actual pages — NO placeholder for FAB
  final List<Widget> _pages = [
    const DashboardScreen(),   // tab 0 → page 0
    const BudgetScreen(),      // tab 1 → page 1
    const PaymentsScreen(),    // tab 3 → page 2
    const StatisticsScreen(),  // tab 4 → page 3
  ];

  // Map tab index → page index (skipping tab 2 which is FAB)
  int _tabToPage(int tabIndex) {
    if (tabIndex < 2) return tabIndex;
    return tabIndex - 1; // tab 3→page 2, tab 4→page 3
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      _showAddTransactionModal();
      return;
    }
    
    ref.read(navigationProvider.notifier).state = index;
    _pageController.jumpToPage(_tabToPage(index));
  }

  void _showAddTransactionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransactionModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTabIndex = ref.watch(navigationProvider);

    // Listen for navigation changes to update PageController
    ref.listen(navigationProvider, (previous, next) {
      if (next != 2 && _pageController.hasClients) {
        _pageController.jumpToPage(_tabToPage(next));
      }
    });

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionModal,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTabIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            activeIcon: Icon(Icons.pie_chart),
            label: 'Bütçe',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(height: 20),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Hesaplar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'İstatistik',
          ),
        ],
      ),
    );
  }
}

