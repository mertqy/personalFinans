import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_screen.dart';
import 'statistics_screen.dart';
import 'payments_screen.dart';
import 'budget_screen.dart';

import '../providers/navigation_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const DashboardScreen(),
    const BudgetScreen(),
    const PaymentsScreen(),
    const StatisticsScreen(),
  ];

  void _onTabTapped(int index) {
    ref.read(navigationProvider.notifier).state = index;
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final currentTabIndex = ref.watch(navigationProvider);

    // Listen for navigation changes to update PageController
    ref.listen(navigationProvider, (previous, next) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(next);
      }
    });

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTabIndex > 3 ? 3 : currentTabIndex, // bounds check if returning from previous 5 tab layout
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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

