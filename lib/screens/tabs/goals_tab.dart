import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/budget_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../core/utils.dart';
import '../../models/goal.dart';
import '../../models/transaction.dart';
import '../../widgets/add_goal_modal.dart';
import '../../widgets/goal_success_dialog.dart';
import '../../core/formatters.dart';

class GoalsTab extends ConsumerWidget {
  const GoalsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalProvider);
    final activeGoals = goals.where((g) => !g.isCompleted).toList();
    final completedGoals = goals.where((g) => g.isCompleted).toList();

    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flag_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Henüz bir birikim hedefi oluşturmadınız.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddGoal(context, ref, goals.length),
              icon: const Icon(Icons.add),
              label: const Text('Hedef Ekle'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddButton(context, ref, goals.length),
          if (activeGoals.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Aktif Hedefler',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            ...activeGoals.map((g) => _buildGoalCard(context, ref, g)),
          ],
          if (completedGoals.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 24.0, bottom: 8.0),
              child: Text(
                'Tamamlanan Hedefler',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ),
            ...completedGoals.map((g) => _buildGoalCard(context, ref, g)),
          ],
          const SizedBox(height: 80), // For FAB/Bottom Bar
        ],
      ),
    );
  }

  Widget _buildAddButton(
    BuildContext context,
    WidgetRef ref,
    int currentCount,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: OutlinedButton.icon(
        onPressed: () => _showAddGoal(context, ref, currentCount),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Hedef Ekle'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showAddGoal(BuildContext context, WidgetRef ref, int currentCount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => const AddGoalModal(),
    );
  }

  Widget _buildGoalCard(BuildContext context, WidgetRef ref, Goal goal) {
    final progress =
        goal.currentAmount / (goal.targetAmount == 0 ? 1 : goal.targetAmount);
    final themeColor = Color(
      int.parse(
        (goal.levelColor.isEmpty ? '#64B5F6' : goal.levelColor).replaceFirst(
          '#',
          'ff',
        ),
        radix: 16,
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: goal.isCompleted ? 0 : 2,
      color: goal.isCompleted
          ? Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : null,
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
                    CircleAvatar(
                      backgroundColor: themeColor.withValues(alpha: 0.1),
                      child: Text(
                        goal.icon.isNotEmpty ? goal.icon : '🎯',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            decoration: goal.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (goal.isCompleted)
                          const Text(
                            'TAMAMLANDI 🎉',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) {
                    if (val == 'edit') {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (c) => AddGoalModal(goal: goal),
                      );
                    } else if (val == 'delete') {
                      _confirmDelete(context, ref, goal);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Sil', style: TextStyle(color: Colors.red)),
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
                goal.isCompleted ? Colors.green : themeColor,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppUtils.formatCurrency(goal.currentAmount)} / ${AppUtils.formatCurrency(goal.targetAmount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Target: ${DateFormat('MMMM yyyy', 'tr_TR').format(goal.targetDate)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (goal.isCompleted ? Colors.green : themeColor)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '%${NumberFormat('##0.0', 'tr_TR').format(progress * 100).replaceAll('.0', '')}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: goal.isCompleted ? Colors.green : themeColor,
                    ),
                  ),
                ),
              ],
            ),
            if (!goal.isCompleted) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showDepositDialog(context, ref, goal),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Para Biriktir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDepositDialog(BuildContext context, WidgetRef ref, Goal goal) {
    final amountController = TextEditingController();
    String? selectedAccountId;
    final accounts = ref
        .read(accountProvider)
        .where((acc) => acc.type != 'investment')
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('${goal.title} İçin Birikim Yap'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Tutar',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedAccountId,
                items: accounts
                    .map(
                      (acc) => DropdownMenuItem(
                        value: acc.id,
                        child: Text(
                          '${acc.name} (${AppUtils.formatCurrency(acc.balance)})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => selectedAccountId = val),
                decoration: const InputDecoration(labelText: 'Hangi Hesaptan?'),
                hint: const Text('Hesap Seçiniz'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = ThousandsSeparatorInputFormatter.parse(
                  amountController.text,
                );
                if (amount <= 0 || selectedAccountId == null) return;

                final account = accounts.firstWhere(
                  (a) => a.id == selectedAccountId,
                );
                if (account.balance < amount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yetersiz bakiye!')),
                  );
                  return;
                }

                // Create a transfer transaction
                final transaction = Transaction(
                  id: AppUtils.generateId(),
                  userId: 'local_user',
                  type: 'transfer',
                  amount: amount,
                  category: 'Transfer',
                  description: '${goal.title} hedefi için birikim',
                  date: DateTime.now(),
                  isPlanned: false,
                  accountId: selectedAccountId!,
                  toGoalId: goal.id,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                ref
                    .read(transactionProvider.notifier)
                    .addTransaction(transaction);

                Navigator.pop(ctx);

                // Check for completion after a slight delay to allow provider to update
                Future.delayed(const Duration(milliseconds: 300), () {
                  final updatedGoals = ref.read(goalProvider);
                  final updatedGoal = updatedGoals.firstWhere(
                    (g) => g.id == goal.id,
                  );
                  if (updatedGoal.isCompleted) {
                    if (!context.mounted) return;
                    GoalSuccessDialog.show(context, updatedGoal);
                  }
                });
              },
              child: const Text('Biriktir'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Goal goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hedefi Sil'),
        content: Text(
          '${goal.title} hedefini silmek istediğinize emin misiniz? Biriken tutar hesaplara geri aktarılmaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(goalProvider.notifier).deleteGoal(goal.id);
              Navigator.pop(ctx);
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
