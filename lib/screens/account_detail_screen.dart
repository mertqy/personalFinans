import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../providers/transaction_provider.dart';
import '../core/utils.dart';

class AccountDetailScreen extends ConsumerWidget {
  final Account account;

  const AccountDetailScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider)
        .where((tx) => tx.accountId == account.id)
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Hero(
                tag: 'acc_name_${account.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    account.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Hero(
                    tag: 'acc_balance_${account.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        AppUtils.formatCurrency(account.balance, currency: account.currency),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Hesap Hareketleri',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          transactions.isEmpty
              ? const SliverFillRemaining(
                  child: Center(child: Text('Henüz hareket yok.')),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tx = transactions[index];
                      final isIncome = tx.type == 'income';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          child: Icon(
                            isIncome ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(tx.description),
                        subtitle: Text(AppUtils.formatDate(tx.date)),
                        trailing: Text(
                          '${isIncome ? '+' : '-'}${AppUtils.formatCurrency(tx.amount, currency: account.currency)}',
                          style: TextStyle(
                            color: isIncome ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                    childCount: transactions.length,
                  ),
                ),
        ],
      ),
    );
  }
}
