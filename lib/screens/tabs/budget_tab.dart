import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/account_provider.dart';
import '../../providers/credit_card_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../core/utils.dart';
import '../../widgets/add_budget_modal.dart';

class BudgetTab extends ConsumerWidget {
  const BudgetTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetProvider);
    final transactions = ref.watch(transactionProvider);
    final accounts = ref.watch(accountProvider);
    final creditCards = ref.watch(creditCardProvider);

    return budgets.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Henüz bir bütçe oluşturmadınız.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (c) => const AddBudgetModal(),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Bütçe Ekle'),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: budgets.length + 1,
            itemBuilder: (context, index) {
              if (index == budgets.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (c) => const AddBudgetModal(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Yeni Bütçe Ekle'),
                  ),
                );
              }

              final budget = budgets[index];
              
              // Gerçek harcamaları hesapla
              final spentAmount = transactions
                  .where((tx) => tx.type == 'expense' && tx.category == budget.categoryId)
                  // Not: Basitleştirilmiş tarih kontrolü (mevcut ay)
                  .where((tx) => tx.date.month == DateTime.now().month && tx.date.year == DateTime.now().year)
                  .fold(0.0, (sum, tx) {
                    String currency = 'TRY';
                    if (tx.accountId.isNotEmpty) {
                      final acc = accounts.where((a) => a.id == tx.accountId).firstOrNull;
                      if (acc != null) currency = acc.currency;
                    } else if (tx.creditCardId != null) {
                      final card = creditCards.where((c) => c.id == tx.creditCardId).firstOrNull;
                      if (card != null) {
                        final acc = accounts.where((a) => a.id == card.accountId).firstOrNull;
                        if (acc != null) currency = acc.currency;
                      }
                    }
                    return sum + AppUtils.convertToBaseCurrency(tx.amount, currency, 'TRY');
                  });

              final progress = spentAmount / (budget.amount == 0 ? 1 : budget.amount);
              final isOverBudget = progress > 1.0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(AppUtils.getCategoryIcon(budget.categoryId), style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Text(AppUtils.getCategoryName(budget.categoryId), 
                                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          Text(
                            AppUtils.formatCurrency(budget.amount),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress > 1.0 ? 1.0 : progress,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(isOverBudget ? Colors.red : Theme.of(context).colorScheme.primary),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${AppUtils.formatCurrency(spentAmount)} harcandı', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('Kalan: ${AppUtils.formatCurrency(budget.amount - spentAmount)}', 
                               style: TextStyle(fontSize: 12, color: isOverBudget ? Colors.red : Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
