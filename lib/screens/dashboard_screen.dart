import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/credit_card_provider.dart';

import '../core/utils.dart';
import '../providers/navigation_provider.dart';
import '../widgets/transaction_modal.dart';
import '../providers/exchange_rate_provider.dart';
import '../services/storage_service.dart';
import '../widgets/mini_heatmap.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountProvider);
    final transactions = ref.watch(transactionProvider);
    final budgets = ref.watch(budgetProvider);
    final creditCards = ref.watch(creditCardProvider);
    final plannedCount = transactions.where((t) => t.isPlanned).length;

    // Notifications calculation
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int budgetWarningCount = 0;
    for (final budget in budgets) {
      final spent = transactions
          .where((tx) => tx.type == 'expense' && tx.category == budget.categoryId)
          .where((tx) => tx.date.month == now.month && tx.date.year == now.year && !tx.isPlanned)
          .fold(0.0, (sum, tx) => sum + AppUtils.getDisplayTRYAmount(tx, accounts, creditCards));
      if (spent / (budget.amount == 0 ? 1 : budget.amount) >= 0.8) budgetWarningCount++;
    }

    int cardReminderCount = 0;
    for (final card in creditCards) {
      if (card.currentDebt <= 0) continue;
      final dueDate = DateTime(now.year, now.month, card.dueDay);
      final adjustedDue = dueDate.isBefore(today) ? DateTime(now.year, now.month + 1, card.dueDay) : dueDate;
      if (adjustedDue.difference(today).inDays <= 3) cardReminderCount++;
    }

    final totalNotifications = plannedCount + budgetWarningCount + cardReminderCount;
    
    // Total Balance in TRY
    double totalBalanceTRY = accounts.fold(0, (sum, acc) => sum + AppUtils.convertToBaseCurrency(acc.balance, acc.currency, 'TRY'));
    
    final recentTransactions = transactions.where((t) => !t.isPlanned).take(4).toList();

    final monthlyTransactions = transactions.where((t) =>
        !t.isPlanned && t.date.month == now.month && t.date.year == now.year).toList();
        
    double calculateMonthlyTotal(String type) {
      double totalTRY = 0.0;
      for (final tx in monthlyTransactions.where((t) => t.type == type)) {
        String currency = 'TRY';
        if (tx.accountId.isNotEmpty) {
          final acc = accounts.where((a) => a.id == tx.accountId).firstOrNull;
          if (acc != null) currency = acc.currency;
        }
        totalTRY += AppUtils.convertToBaseCurrency(tx.amount, currency, 'TRY');
      }
      return totalTRY;
    }

    final monthlyIncomeTRY = calculateMonthlyTotal('income');
    final monthlyExpenseTRY = calculateMonthlyTotal('expense');

    String userName = StorageService.settingsBox.get('user_name', defaultValue: 'Alex Johnson') as String;
    if (userName.isEmpty) userName = 'Alex Johnson';
    final userInitials = userName.isNotEmpty && userName.contains(' ') 
        ? '${userName.split(' ')[0][0]}${userName.split(' ')[1][0]}' 
        : (userName.isNotEmpty ? userName[0] : 'U');

    // Matching Colors from provided image
    final bgColor = const Color(0xFF141724);
    final cardColor = const Color(0xFF1C2235);
    final purpleGradient = const LinearGradient(
      colors: [Color(0xFF6B5BF2), Color(0xFF5A49F2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final incomeBoxColor = const Color(0xFF102722);
    final incomeButtonColor = const Color(0xFF00D287);
    final expenseBoxColor = const Color(0xFF28181D);
    final expenseButtonColor = const Color(0xFFFF4B65);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TEKRAR HOŞ GELDİN,',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: purpleGradient,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B5BF2).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            userInitials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (totalNotifications > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6B),
                              shape: BoxShape.circle,
                              border: Border.all(color: bgColor, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ).animate().fade(duration: 400.ms).slide(begin: const Offset(0, -0.2)),
              const SizedBox(height: 24),

              // Total Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: purpleGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B5BF2).withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toplam Varlık',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppUtils.formatCurrency(totalBalanceTRY, currency: 'TRY'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildRatesPillRow(ref),
                  ],
                ),
              ).animate(delay: 100.ms).fade(duration: 500.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack),
              const SizedBox(height: 16),

              // Income / Expense Row
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const TransactionModal(initialType: 'income'),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: incomeBoxColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: incomeButtonColor.withValues(alpha: 0.1), width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GELİR',
                                  style: TextStyle(
                                    color: incomeButtonColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '+${AppUtils.formatCurrency(monthlyIncomeTRY, currency: 'TRY')}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: incomeButtonColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const TransactionModal(initialType: 'expense'),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: expenseBoxColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: expenseButtonColor.withValues(alpha: 0.1), width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GİDER',
                                  style: TextStyle(
                                    color: expenseButtonColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '-${AppUtils.formatCurrency(monthlyExpenseTRY, currency: 'TRY')}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: expenseButtonColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.remove, color: Colors.white, size: 20), // changed to remove for expense consistency (optional but good)
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate(delay: 200.ms).fade(duration: 400.ms).slideX(begin: 0.1),
              const SizedBox(height: 24),

              // Harcama Lokasyonları 
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Harcama Lokasyonları',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Embedded Map
                    const MiniHeatmap(),
                    const SizedBox(height: 16),
                    // Real location transactions
                    if (transactions.where((tx) => tx.locationLat != null && tx.locationLng != null).isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: Text("Henüz konum verili harcama yok.", style: TextStyle(color: Colors.white54, fontSize: 13)),
                        ),
                      )
                    else 
                      ...transactions
                        .where((tx) => tx.locationLat != null && tx.locationLng != null)
                        .take(3)
                        .map((tx) {
                          final locationList = transactions.where((tx) => tx.locationLat != null && tx.locationLng != null).take(3).toList();
                          final isLast = tx == locationList.last;
                          final convertedAmount = AppUtils.getDisplayTRYAmount(tx, accounts, []); 
                          final displayCurrency = tx.type == 'transfer' ? AppUtils.getEffectiveCurrency(tx, accounts, []) : 'TRY';

                          return Column(
                            children: [
                              _buildLocationItem(
                                Icons.location_on_outlined, 
                                tx.description.isNotEmpty ? tx.description : AppUtils.getCategoryName(tx.category), 
                                '${DateFormat('d MMM', 'tr_TR').format(tx.date)} • ${AppUtils.getCategoryName(tx.category)}', 
                                '${tx.type == 'income' ? '+' : '-'}${AppUtils.formatCurrency(convertedAmount, currency: displayCurrency)}',
                                tx.type == 'income' ? const Color(0xFF00D287) : const Color(0xFFFF4B65),
                              ),
                              if (!isLast)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(color: Colors.white12, height: 1),
                                ),
                            ],
                          );
                        }),
                  ],
                ),
              ).animate(delay: 300.ms).fade(duration: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: 24),

              // İşlem Geçmişi
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'İşlem Geçmişi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(navigationProvider.notifier).state = 4;
                          },
                          child: Text(
                            'Tümünü Gör',
                            style: TextStyle(color: const Color(0xFF6B5BF2).withValues(alpha: 0.8), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    recentTransactions.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: Text("Henüz işlem yok.", style: TextStyle(color: Colors.white54))),
                          )
                        : Column(
                            children: recentTransactions.map((tx) {
                              final isIncome = tx.type == 'income';
                              final convertedAmount = AppUtils.getDisplayTRYAmount(tx, accounts, creditCards); 
                              final displayCurrency = tx.type == 'transfer' ? AppUtils.getEffectiveCurrency(tx, accounts, creditCards) : 'TRY';
                              
                              Color iconColor = isIncome ? const Color(0xFF00D287) : const Color(0xFFFF4B65);
                              if (tx.type == 'transfer') iconColor = const Color(0xFF4A89F3);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: InkWell(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => TransactionModal(transaction: tx),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: iconColor.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: iconColor.withValues(alpha: 0.2), width: 1),
                                        ),
                                        child: Center(
                                          child: Text(AppUtils.getCategoryIcon(tx.category), style: const TextStyle(fontSize: 20)),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tx.description.isNotEmpty ? tx.description : AppUtils.getCategoryName(tx.category),
                                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${DateFormat('d MMM yyyy', 'tr_TR').format(tx.date)} • ${DateFormat('HH:mm').format(tx.date)}',
                                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${tx.type == 'income' ? '+' : (tx.type == 'expense' ? '-' : '')}${AppUtils.formatCurrency(convertedAmount, currency: displayCurrency)}',
                                        style: TextStyle(
                                          color: isIncome ? const Color(0xFF00D287) : const Color(0xFFFF4B65),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ).animate(delay: 400.ms).fade(duration: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: 24),

              // Bottom Action Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildLargeActionBtn(
                      title: 'İşlem\nEkle',
                      icon: Icons.add,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (c) => const TransactionModal(initialType: 'expense'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildLargeActionBtn(
                      title: 'Döviz/Altın\nTakas',
                      icon: Icons.swap_horiz,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (c) => const TransactionModal(initialType: 'transfer'),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationItem(IconData icon, String title, String subtitle, String amount, [Color amountColor = Colors.white]) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6B5BF2).withValues(alpha: 0.7), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
        Text(amount, style: TextStyle(color: amountColor, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLargeActionBtn({required String title, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF141724), 
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFF282B3E), width: 1),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFF202334),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF7A6AF5), size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatesPillRow(WidgetRef ref) {
    final ratesState = ref.watch(exchangeRateProvider);
    final usdRate = ratesState.where((r) => r.code == 'USD').firstOrNull?.rate ?? AppUtils.exchangeRates['USD'] ?? 32.95;
    final goldRate = ratesState.where((r) => r.code == 'GOLD').firstOrNull?.rate ?? AppUtils.exchangeRates['GOLD'] ?? 2342;

    return Row(
      children: [
        _buildRatePill('USD/TRY', usdRate.toStringAsFixed(2), true),
        const SizedBox(width: 8),
        _buildRatePill('ALTIN/USD', '\$${goldRate.toStringAsFixed(0)}', false),
      ],
    );
  }

  Widget _buildRatePill(String label, String value, bool isUp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Icon(
            isUp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: isUp ? const Color(0xFF00D287) : const Color(0xFFFF4B65),
            size: 14,
          ),
        ],
      ),
    );
  }
}
