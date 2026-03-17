import 'package:flutter/material.dart';
import 'tabs/budget_tab.dart';
import 'tabs/goals_tab.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bütçe ve Hedefler'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bütçeler'),
              Tab(text: 'Birikim Hedefleri'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BudgetTab(),
            GoalsTab(),
          ],
        ),
      ),
    );
  }
}
