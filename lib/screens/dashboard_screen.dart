import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/credit_card_provider.dart';
import '../core/utils.dart';
import '../providers/navigation_provider.dart';
import '../widgets/transaction_modal.dart';
import 'notifications_screen.dart';
import '../services/insights_service.dart';
import '../providers/exchange_rate_provider.dart';
import '../services/storage_service.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../widgets/mini_heatmap.dart'; // Added import

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountProvider);
    final transactions = ref.watch(transactionProvider);
    final budgets = ref.watch(budgetProvider);
    final goals = ref.watch(goalProvider);
    final creditCards = ref.watch(creditCardProvider);
    final plannedCount = transactions.where((t) => t.isPlanned).length;

    // Bütçe uyarı sayısı
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int budgetWarningCount = 0;
    for (final budget in budgets) {
      final spent = transactions
          .where((tx) => tx.type == 'expense' && tx.category == budget.categoryId)
          .where((tx) => tx.date.month == now.month && tx.date.year == now.year && !tx.isPlanned)
          .fold(0.0, (sum, tx) => sum + tx.amount);
      if (spent / (budget.amount == 0 ? 1 : budget.amount) >= 0.8) budgetWarningCount++;
    }

    // Kredi kartı hatırlatma sayısı
    int cardReminderCount = 0;
    for (final card in creditCards) {
      if (card.currentDebt <= 0) continue;
      final dueDate = DateTime(now.year, now.month, card.dueDay);
      final adjustedDue = dueDate.isBefore(today) ? DateTime(now.year, now.month + 1, card.dueDay) : dueDate;
      if (adjustedDue.difference(today).inDays <= 3) cardReminderCount++;
    }

    final totalNotifications = plannedCount + budgetWarningCount + cardReminderCount;

    double totalBalance = accounts.fold(0, (sum, acc) => sum + AppUtils.convertToBaseCurrency(acc.balance, acc.currency, 'TRY'));
    
    final recentTransactions = transactions.where((t) => !t.isPlanned).take(5).toList();

    // Aylık gelir/gider hesaplaması
    final monthlyTransactions = transactions.where((t) =>
        !t.isPlanned && t.date.month == now.month && t.date.year == now.year).toList();
    final monthlyIncome = monthlyTransactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final monthlyExpense = monthlyTransactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Param Nerede'),
        actions: [
          IconButton(
            icon: Badge(
              label: Text(totalNotifications.toString()),
              isLabelVisible: totalNotifications > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hoşgeldin Mesajı
            Builder(builder: (context) {
              final userName = StorageService.settingsBox.get('user_name', defaultValue: '');
              if (userName.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merhaba, $userName 👋',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bugün finansal durumun nasıl?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              );
            }),

            // Bakiye Kartı
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Toplam Varlık',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppUtils.formatCurrency(totalBalance, currency: 'TRY'),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Aylık Gelir / Gider Özeti
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.arrow_downward, color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            Text('Gelir', style: TextStyle(color: Colors.green.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppUtils.formatCurrency(monthlyIncome, currency: 'TRY'),
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.arrow_upward, color: Colors.red, size: 16),
                            const SizedBox(width: 4),
                            Text('Gider', style: TextStyle(color: Colors.red.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppUtils.formatCurrency(monthlyExpense, currency: 'TRY'),
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildCurrencyRates(context, ref),
            const SizedBox(height: 20),

            // Hızlı İşlem Butonları
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAction(context, Icons.arrow_downward, 'Gelir', Colors.green, () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (c) => const TransactionModal(initialType: 'income'),
                  );
                }),
                _buildQuickAction(context, Icons.arrow_upward, 'Gider', Colors.red, () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (c) => const TransactionModal(initialType: 'expense'),
                  );
                }),
                _buildQuickAction(context, Icons.swap_horiz, 'Transfer', Colors.blue, () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (c) => const TransactionModal(initialType: 'transfer'),
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),

            // Tahmini Ay Sonu Bakiyesi
            Builder(
              builder: (context) {
                final forecast = InsightsService.calculateEndOfMonthForecast(
                  currentBalance: totalBalance,
                  transactions: transactions,
                );
                final diff = forecast - totalBalance;
                final isPositive = diff >= 0;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tahmini Ay Sonu', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                            const SizedBox(height: 2),
                            Text(
                              AppUtils.formatCurrency(forecast, currency: 'TRY'),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${isPositive ? '+' : ''}${AppUtils.formatCurrency(diff, currency: 'TRY')}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isPositive ? Colors.green : Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Akıllı Öneri Kartı
            Builder(
              builder: (context) {
                final insights = InsightsService.generateInsights(transactions);
                if (insights.isEmpty) return const SizedBox.shrink();
                final topInsight = insights.first;
                final isIncrease = topInsight['type'] == 'increase';
                final color = isIncrease ? Colors.orange : Colors.green;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Text(topInsight['icon'] as String, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Akıllı Öneri', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                            const SizedBox(height: 4),
                            Text(
                              topInsight['message'] as String,
                              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const MiniHeatmap(),
            const SizedBox(height: 24),

            // Son İşlemler Başlığı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Son İşlemler', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () {
                    ref.read(navigationProvider.notifier).state = 4;
                  },
                  child: const Text('Tümünü Gör'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Son İşlemler Listesi
            recentTransactions.isEmpty
                ? const Center(
                    child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text("Henüz işlem bulunmuyor."),
                  ))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = recentTransactions[index];
                      final isIncome = tx.type == 'income';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => TransactionModal(transaction: tx),
                            );
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isIncome ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(AppUtils.getCategoryIcon(tx.category), style: const TextStyle(fontSize: 20)),
                          ),
                          title: Text(
                            tx.description == 'Transfer' && tx.type == 'transfer'
                                ? (_getTransferTitle(tx, accounts, creditCards, goals))
                                : tx.description,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${tx.type == 'transfer' ? 'Transfer' : AppUtils.getCategoryName(tx.category)} • ${AppUtils.formatDate(tx.date)}',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                          trailing: Builder(
                            builder: (context) {
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
                              
                              final convertedAmount = AppUtils.convertToBaseCurrency(tx.amount, currency, 'TRY');
                              
                              return Text(
                                '${isIncome ? '+' : '-'}${AppUtils.formatCurrency(convertedAmount, currency: 'TRY')}',
                                style: TextStyle(
                                  color: isIncome ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyRates(BuildContext context, WidgetRef ref) {
    final ratesState = ref.watch(exchangeRateProvider);
    final lastUpdated = ratesState.isNotEmpty ? ratesState.first.lastUpdated : null;

    final List<String> codes = ['USD', 'EUR', 'GOLD'];
    final Map<String, String> icons = {
      'USD': '🇺🇸',
      'EUR': '🇪🇺',
      'GOLD': '🟡',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Canlı Kurlar', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            Row(
              children: [
                if (lastUpdated != null)
                  Text(
                    'Son: ${DateFormat('HH:mm').format(lastUpdated)}',
                    style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => ref.read(exchangeRateProvider.notifier).refreshRates(),
                  icon: const Icon(Icons.refresh, size: 14),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Kurları Güncelle',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: codes.map((code) {
              final rateObj = ratesState.where((r) => r.code == code).firstOrNull;
              final rate = rateObj?.rate ?? (AppUtils.exchangeRates[code] ?? 0.0);
              
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(icons[code] ?? '', style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(code == 'GOLD' ? 'Altın' : code, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppUtils.formatCurrency(rate, currency: 'TRY'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getTransferTitle(Transaction tx, List<dynamic> accounts, List<dynamic> cards, List<Goal> goals) {
    String from = 'Bilinmeyen';
    if (tx.creditCardId != null) {
      final card = cards.where((c) => c.id == tx.creditCardId).firstOrNull;
      from = card?.name ?? 'Kart';
    } else {
      final acc = accounts.where((a) => a.id == tx.accountId).firstOrNull;
      from = acc?.name ?? 'Hesap';
    }

    String to = 'Bilinmeyen';
    if (tx.toAccountId != null) {
      final acc = accounts.where((a) => a.id == tx.toAccountId).firstOrNull;
      to = acc?.name ?? 'Hesap';
    } else if (tx.toGoalId != null) {
      final goal = goals.where((g) => g.id == tx.toGoalId).firstOrNull;
      to = goal?.title ?? 'Hedef';
    }

    return '$from ➔ $to';
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
