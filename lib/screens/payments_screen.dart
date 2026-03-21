import 'package:flutter/material.dart';
import 'tabs/accounts_tab.dart';
import 'tabs/cards_tab.dart';
import 'tabs/loans_tab.dart';
import 'tabs/subscriptions_tab.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hesaplar ve Kartlar'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Hesaplar'),
              Tab(text: 'Kartlar'),
              Tab(text: 'Krediler'),
              Tab(text: 'Abonelikler'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AccountsTab(),
            CardsTab(),
            LoansTab(),
            SubscriptionsTab(),
          ],
        ),
      ),
    );
  }
}
