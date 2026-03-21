import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/credit_card_provider.dart';
import '../providers/subscription_provider.dart';
import '../core/utils.dart';
import '../widgets/transaction_modal.dart';
import '../models/transaction.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);
    final budgets = ref.watch(budgetProvider);
    final creditCards = ref.watch(creditCardProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // --- Planlanmış İşlemler ---
    final plannedTransactions = transactions.where((t) => t.isPlanned).toList();
    final lateTransactions = plannedTransactions.where((t) => t.date.isBefore(today)).toList();
    final upcomingTransactions = plannedTransactions
        .where((t) => !t.date.isBefore(today))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // --- Bütçe Uyarıları ---
    final budgetWarnings = <Map<String, dynamic>>[];
    for (final budget in budgets) {
      final spentAmount = transactions
          .where((tx) => tx.type == 'expense' && tx.category == budget.categoryId)
          .where((tx) => tx.date.month == now.month && tx.date.year == now.year && !tx.isPlanned)
          .fold(0.0, (sum, tx) => sum + tx.amount);
      final progress = spentAmount / (budget.amount == 0 ? 1 : budget.amount);
      if (progress >= 0.8) {
        budgetWarnings.add({
          'category': budget.categoryId,
          'spent': spentAmount,
          'limit': budget.amount,
          'progress': progress,
          'isOver': progress >= 1.0,
        });
      }
    }

    // --- Kredi Kartı Hatırlatmaları ---
    final cardReminders = <Map<String, dynamic>>[];
    for (final card in creditCards) {
      if (card.currentDebt <= 0) continue;
      
      // Son ödeme günü hesaplama
      final dueDate = DateTime(now.year, now.month, card.dueDay);
      final adjustedDue = dueDate.isBefore(today) 
          ? DateTime(now.year, now.month + 1, card.dueDay) 
          : dueDate;
      final daysUntilDue = adjustedDue.difference(today).inDays;
      
      // Hesap kesim tarihi hesaplama
      final statementDate = DateTime(now.year, now.month, card.statementDay);
      final adjustedStatement = statementDate.isBefore(today) 
          ? DateTime(now.year, now.month + 1, card.statementDay) 
          : statementDate;
      final daysUntilStatement = adjustedStatement.difference(today).inDays;

      if (daysUntilDue <= 3) {
        cardReminders.add({
          'type': 'due',
          'card': card,
          'daysLeft': daysUntilDue,
          'date': adjustedDue,
        });
      }
      if (daysUntilStatement <= 1) {
        cardReminders.add({
          'type': 'statement',
          'card': card,
          'daysLeft': daysUntilStatement,
          'date': adjustedStatement,
        });
      }
    }

    // --- Abonelik Hatırlatmaları ---
    final subscriptions = ref.watch(subscriptionProvider);
    final subReminders = <Map<String, dynamic>>[];
    for (final sub in subscriptions.where((s) => s.isActive)) {
      final nextBilling = DateTime(now.year, now.month, sub.billingDay);
      final adjustedNext = nextBilling.isBefore(today)
          ? DateTime(now.year, now.month + 1, sub.billingDay)
          : nextBilling;
      final daysUntil = adjustedNext.difference(today).inDays;
      if (daysUntil <= 3) {
        subReminders.add({
          'sub': sub,
          'daysLeft': daysUntil,
          'date': adjustedNext,
        });
      }
    }

    final hasContent = plannedTransactions.isNotEmpty || budgetWarnings.isNotEmpty || cardReminders.isNotEmpty || subReminders.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: !hasContent
          ? _buildEmptyState(context)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Abonelik Hatırlatmaları
                if (subReminders.isNotEmpty) ...[
                  _buildSectionTitle(context, 'Abonelik Ödemeleri', const Color(0xFF6C5CE7)),
                  ...subReminders.map((r) {
                    final sub = r['sub'];
                    final daysLeft = r['daysLeft'] as int;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(sub.icon, style: const TextStyle(fontSize: 22)),
                        ),
                        title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          daysLeft == 0 ? 'Bugün ödenecek!' : '$daysLeft gün sonra',
                          style: TextStyle(color: daysLeft == 0 ? Colors.red : const Color(0xFF6C5CE7), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          AppUtils.formatCurrency(sub.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],

                // Bütçe Uyarıları
                if (budgetWarnings.isNotEmpty) ...[
                  _buildSectionTitle(context, 'Bütçe Uyarıları', Colors.orange),
                  ...budgetWarnings.map((w) => _buildBudgetWarningCard(context, w)),
                  const SizedBox(height: 24),
                ],

                // Kredi Kartı Hatırlatmaları
                if (cardReminders.isNotEmpty) ...[
                  _buildSectionTitle(context, 'Kredi Kartı Hatırlatmaları', Colors.purple),
                  ...cardReminders.map((r) => _buildCardReminderCard(context, r)),
                  const SizedBox(height: 24),
                ],

                // Gecikmiş Planlar
                if (lateTransactions.isNotEmpty) ...[
                  _buildSectionTitle(context, 'Gecikmiş Ödemeler/Planlar', Colors.red),
                  ...lateTransactions.map((tx) => _buildNotificationCard(context, ref, tx, isLate: true)),
                  const SizedBox(height: 24),
                ],

                // Yaklaşan Planlar
                if (upcomingTransactions.isNotEmpty) ...[
                  _buildSectionTitle(context, 'Yaklaşan Planlar', Theme.of(context).colorScheme.primary),
                  ...upcomingTransactions.map((tx) => _buildNotificationCard(context, ref, tx)),
                ],
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('Henüz bir bildirim yok.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
      ),
    );
  }

  // --- Bütçe Uyarı Kartı ---
  Widget _buildBudgetWarningCard(BuildContext context, Map<String, dynamic> warning) {
    final isOver = warning['isOver'] as bool;
    final progress = warning['progress'] as double;
    final spent = warning['spent'] as double;
    final limit = warning['limit'] as double;
    final categoryId = warning['category'] as String;
    final percent = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOver ? Colors.red.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isOver ? Colors.red : Colors.orange).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(AppUtils.getCategoryIcon(categoryId), style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppUtils.getCategoryName(categoryId),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOver
                            ? '⚠️ Bütçe aşıldı! (%$percent)'
                            : '⚡ Bütçe limite yaklaşıyor (%$percent)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOver ? Colors.red : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress > 1.0 ? 1.0 : progress,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(isOver ? Colors.red : Colors.orange),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${AppUtils.formatCurrency(spent)} harcandı', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text('Limit: ${AppUtils.formatCurrency(limit)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Kredi Kartı Hatırlatma Kartı ---
  Widget _buildCardReminderCard(BuildContext context, Map<String, dynamic> reminder) {
    final card = reminder['card'];
    final daysLeft = reminder['daysLeft'] as int;
    final type = reminder['type'] as String;
    final isDue = type == 'due';

    final color = isDue ? Colors.red : Colors.blue;
    final icon = isDue ? Icons.payment : Icons.receipt_long;
    final title = isDue ? '${card.bank} - Son Ödeme Günü' : '${card.bank} - Hesap Kesim';
    final subtitle = daysLeft == 0
        ? (isDue ? 'Son ödeme günü bugün!' : 'Hesap kesim bugün!')
        : (isDue ? '$daysLeft gün sonra son ödeme' : '$daysLeft gün sonra hesap kesim');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            if (isDue)
              Text('Borç: ${AppUtils.formatCurrency(card.currentDebt)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // --- Planlanmış İşlem Kartı ---
  Widget _buildNotificationCard(BuildContext context, WidgetRef ref, Transaction tx, {bool isLate = false}) {
    final isIncome = tx.type == 'income';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isLate ? Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isIncome ? Colors.green : Colors.red).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isIncome ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${tx.category} • ${AppUtils.formatDate(tx.date)}'),
            if (isLate)
              const Text('Ödeme günü geçti!', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppUtils.formatCurrency(tx.amount),
              style: TextStyle(
                color: isIncome ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                  onPressed: () => _confirmComplete(context, ref, tx),
                  tooltip: 'Tamamlandı Olarak İşaretle',
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => TransactionModal(transaction: tx),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmComplete(BuildContext context, WidgetRef ref, Transaction tx) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İşlemi Tamamla'),
        content: Text('"${tx.description}" işlemini bugün gerçekleşmiş olarak işaretlemek istiyor musunuz? Bakiyeniz güncellenecektir.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              ref.read(transactionProvider.notifier).completePlannedTransaction(tx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İşlem tamamlandı ve bakiye güncellendi.')));
            },
            child: const Text('Tamamla'),
          ),
        ],
      ),
    );
  }
}
