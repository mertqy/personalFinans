import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../core/utils.dart';

class AccountDetailScreen extends ConsumerWidget {
  final Account account;

  const AccountDetailScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAccounts = ref.watch(accountProvider);
    final transactions = ref.watch(transactionProvider)
        .where((tx) => tx.accountId == account.id || tx.toAccountId == account.id)
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
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'acc_balance_${account.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          AppUtils.formatCurrency(
                            AppUtils.convertToBaseCurrency(account.balance, account.currency, 'TRY'),
                            currency: 'TRY',
                          ),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (account.currency != 'TRY')
                      Text(
                        AppUtils.formatCurrency(account.balance, currency: account.currency),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
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
                      // Bir hesap için 'gelir' durumu:
                      // 1. İşlem tipi 'income' ise
                      // 2. İşlem tipi 'transfer' ve bu hesap hedef hesap ise
                      final bool isEffectivelyIncome = tx.type == 'income' || 
                                                     (tx.type == 'transfer' && tx.toAccountId == account.id);
                      
                      final bool isTransfer = tx.type == 'transfer';
                      final bool isOutgoingTransfer = isTransfer && tx.accountId == account.id;

                      // Transferlerde orijinal para birimi, diğerlerinde TRY gösterilecek
                      final txCurrency = isTransfer 
                          ? AppUtils.getEffectiveCurrency(tx, allAccounts, []) 
                          : 'TRY';
                                              
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isEffectivelyIncome 
                              ? Colors.green.withValues(alpha: 0.1) 
                              : (isTransfer ? Colors.blue.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1)),
                          child: Icon(
                            isEffectivelyIncome ? Icons.keyboard_arrow_down : (isTransfer ? Icons.swap_horiz : Icons.keyboard_arrow_up),
                            color: isEffectivelyIncome ? Colors.green : (isTransfer ? Colors.blue : Colors.red),
                          ),
                        ),
                        title: Text(tx.description.isNotEmpty ? tx.description : AppUtils.getCategoryName(tx.category)),
                        subtitle: Text(AppUtils.formatDate(tx.date)),
                        trailing: Text(
                          '${isEffectivelyIncome ? '+' : (isOutgoingTransfer || tx.type == 'expense' ? '-' : '')}${AppUtils.formatCurrency(isTransfer ? tx.amount : AppUtils.getDisplayTRYAmount(tx, allAccounts, []), currency: txCurrency)}',
                          style: TextStyle(
                            color: isEffectivelyIncome ? Colors.green : (isTransfer ? Colors.blue : Colors.red),
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
