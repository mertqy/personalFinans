import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../providers/account_provider.dart';
import '../../providers/credit_card_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../core/utils.dart';
import '../../core/premium_limits.dart';
import '../../widgets/premium_gate.dart';
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.pie_chart_rounded,
                      size: 72,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Bütçeniz Kontrol Altında Olsun',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Harcamalarınızı sınırlandırmak ve ay sonunu rahat getirmek için farklı kategorilerde bütçeler belirleyin.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  FilledButton.icon(
                    onPressed: () => _showAddBudget(context, ref, budgets.length),
                    icon: const Icon(Icons.add_chart_rounded),
                    label: const Text(
                      'İlk Bütçemi Oluştur',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
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
                    onPressed: () => _showAddBudget(context, ref, budgets.length),
                    icon: const Icon(Icons.add),
                    label: const Text('Yeni Bütçe Ekle'),
                  ),
                );
              }

              final budget = budgets[index];

              // Gerçek harcamaları hesapla
              final spentAmount = transactions
                  .where(
                    (tx) =>
                        tx.type == 'expense' &&
                        tx.category == budget.categoryId,
                  )
                  // Not: Basitleştirilmiş tarih kontrolü (mevcut ay)
                  .where(
                    (tx) =>
                        tx.date.month == DateTime.now().month &&
                        tx.date.year == DateTime.now().year,
                  )
                  .fold(0.0, (sum, tx) {
                    String currency = 'TRY';
                    if (tx.accountId.isNotEmpty) {
                      final acc = accounts
                          .where((a) => a.id == tx.accountId)
                          .firstOrNull;
                      if (acc != null) currency = acc.currency;
                    } else if (tx.creditCardId != null) {
                      final card = creditCards
                          .where((c) => c.id == tx.creditCardId)
                          .firstOrNull;
                      if (card != null) {
                        final acc = accounts
                            .where((a) => a.id == card.accountId)
                            .firstOrNull;
                        if (acc != null) currency = acc.currency;
                      }
                    }
                    return sum +
                        AppUtils.convertToBaseCurrency(
                          tx.amount,
                          currency,
                          'TRY',
                        );
                  });

              final progress =
                  spentAmount / (budget.amount == 0 ? 1 : budget.amount);
              final isOverBudget = progress > 1.0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (c) => AddBudgetModal(budget: budget),
                    );
                  },
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
                                Text(
                                  AppUtils.getCategoryIcon(budget.categoryId),
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppUtils.getCategoryName(budget.categoryId),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  AppUtils.formatCurrency(budget.amount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (c) =>
                                            AddBudgetModal(budget: budget),
                                      );
                                    } else if (value == 'delete') {
                                      _confirmDelete(context, ref, budget);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Düzenle'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Bütçeyi Sil',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress > 1.0 ? 1.0 : progress,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOverBudget
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppUtils.formatCurrency(spentAmount)} harcandı',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'Kalan: ${AppUtils.formatCurrency(budget.amount - spentAmount)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOverBudget ? Colors.red : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
  }

  void _showAddBudget(
    BuildContext context,
    WidgetRef ref,
    int currentCount,
  ) async {
    final allowed = await PremiumGate.check(
      context: context,
      ref: ref,
      currentCount: currentCount,
      freeLimit: PremiumLimits.freeBudgetLimit,
    );
    if (!allowed || !context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => const AddBudgetModal(),
    );
  }
 
  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bütçeyi Sil'),
        content: Text(
          '${AppUtils.getCategoryName(budget.categoryId)} kategorisindeki bütçeyi silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(budgetProvider.notifier).deleteBudget(budget.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Bütçe silindi')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
