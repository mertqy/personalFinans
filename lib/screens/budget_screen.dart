import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/budget_provider.dart';
import '../providers/account_provider.dart';
import '../providers/credit_card_provider.dart';
import '../providers/transaction_provider.dart';
import '../core/utils.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../widgets/add_budget_modal.dart';
import '../widgets/add_goal_modal.dart';
import '../widgets/goal_success_dialog.dart';
import '../core/formatters.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Custom Colors matching the design
const _bgColor = Color(0xFF181A25);
const _cardColor = Color(0xFF222634);
const _textGrey = Color(0xFF8A90A5);
const _blueAccent = Color(0xFF5A55E1);
const _purpleAccent = Color(0xFF7B61FF);
const _orangeAccent = Color(0xFFF58735);
const _redAccent = Color(0xFFE53935);
const _greenAccent = Color(0xFF10B981);

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  @override
  Widget build(BuildContext context) {
    final budgets = ref.watch(budgetProvider);
    final goals = ref.watch(goalProvider);
    final transactions = ref.watch(transactionProvider);
    final accounts = ref.watch(accountProvider);
    final creditCards = ref.watch(creditCardProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Bütçe & Hedefler',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        actions: [
          // Simulated PDF button from the design
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Material(
              color: _blueAccent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () {
                  // Stub PDF action
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text('PDF', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- AYLIK HARCAMA HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AYLIK HARCAMA',
                  style: TextStyle(
                    color: _textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DateFormat('MMMM yyyy', 'tr_TR').format(DateTime.now()),
                    style: const TextStyle(
                      color: _textGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ).animate().fade(duration: 400.ms).slideX(begin: -0.1),
            const SizedBox(height: 12),

            // --- AYLIK HARCAMA CARDS ---
            if (budgets.isEmpty)
              _buildEmptyState('Planlı bir bütçeniz yok.', Icons.pie_chart_outline, () => _showAddBudget(context))
            else
               ...budgets.map((b) => _buildBudgetCard(b, transactions, accounts, creditCards)),
            
            // Add budget subtle button
            Center(
              child: TextButton.icon(
                onPressed: () => _showAddBudget(context),
                icon: const Icon(Icons.add, size: 16, color: _blueAccent),
                label: const Text('Yeni Bütçe Ekle', style: TextStyle(color: _blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 24),

            // --- TASARRUF HEDEFLERİ HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TASARRUF HEDEFLERİ',
                  style: TextStyle(
                    color: _textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                InkWell(
                  onTap: () => _showAddGoal(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _blueAccent.withValues(alpha: 0.1),
                      border: Border.all(color: _blueAccent.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add, size: 14, color: _blueAccent),
                        SizedBox(width: 4),
                        Text(
                          'YENİ HEDEF',
                          style: TextStyle(
                            color: _blueAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // --- TASARRUF HEDEFLERİ CARDS ---
            if (goals.isEmpty)
              _buildEmptyState('Henüz bir birikim hedefi oluşturmadınız.', Icons.flag_outlined, () => _showAddGoal(context))
            else
              ...goals.map((g) => _buildGoalCard(g)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg, IconData icon, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _textGrey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: _textGrey.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: _textGrey)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: _blueAccent,
              side: const BorderSide(color: _blueAccent),
            ),
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget, List<Transaction> txs, List<dynamic> accounts, List<dynamic> cards) {
    // Spent amount logic
    final spentAmount = txs
        .where((tx) => tx.type == 'expense' && tx.category == budget.categoryId)
        .where((tx) => tx.date.month == DateTime.now().month && tx.date.year == DateTime.now().year)
        .fold(0.0, (sum, tx) => sum + AppUtils.getDisplayTRYAmount(tx, accounts, cards));

    final double progress = budget.amount == 0 ? 0 : spentAmount / budget.amount;
    
    // Style logic based on progress
    Color titleColor = _textGrey;
    List<Color> gradientColors = [_blueAccent, _purpleAccent];
    Widget? rightBadge;
    Widget? bottomText;

    if (progress <= 0.8) {
      // Normal
      if (progress > 0) {
        rightBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
          ),
          child: const Text('YOLUNDA', style: TextStyle(color: Colors.teal, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        );
      }
    } else if (progress <= 1.0) {
      // Warning
      titleColor = _orangeAccent;
      gradientColors = [_orangeAccent, _orangeAccent];
      rightBadge = const Icon(Icons.error_outline, color: _orangeAccent, size: 20);
      bottomText = Text(
        "Limitin %${(progress * 100).toInt()}'ine ulaşıldı",
        style: const TextStyle(color: _orangeAccent, fontSize: 12, fontWeight: FontWeight.w600),
      );
    } else {
      // Danger
      titleColor = _redAccent;
      gradientColors = [_redAccent, _redAccent];
      rightBadge = const Icon(Icons.warning_amber_rounded, color: _redAccent, size: 20);
      bottomText = Text(
        "Limit Aşımı: ${AppUtils.formatCurrency(spentAmount - budget.amount)}",
        style: const TextStyle(color: _redAccent, fontSize: 12, fontWeight: FontWeight.w600),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: _cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: progress > 1.0 ? const BorderSide(color: _redAccent, width: 0.5) : BorderSide.none,
      ),
      elevation: 0,
      child: InkWell(
        onTap: () {
          // Open edit modal if needed
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppUtils.getCategoryName(budget.categoryId).toUpperCase(),
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (rightBadge != null) rightBadge,
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    AppUtils.formatCurrency(spentAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ ${AppUtils.formatCurrency(budget.amount)}',
                    style: TextStyle(fontSize: 14, color: _textGrey.withValues(alpha: 0.8)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: (progress.clamp(0.0, 1.0) * 100).toInt(),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradientColors),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 100 - (progress.clamp(0.0, 1.0) * 100).toInt(),
                      child: const SizedBox(),
                    ),
                  ],
                ),
              ),
              if (bottomText != null) ...[
                const SizedBox(height: 8),
                bottomText,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final progress = goal.targetAmount == 0 ? 0.0 : goal.currentAmount / goal.targetAmount;
    final isDone = progress >= 1.0;
    
    // Attempt to extract level logic based on design
    final levelNum = (progress * 10).toInt().clamp(1, 10);
    String titleText = "SEVİYE $levelNum: ";
    if (progress < 0.2) {
      titleText += "BAŞLANGIÇ!";
    } else if (progress < 0.5) {
      titleText += "YOLDA!";
    } else if (progress < 0.8) {
      titleText += "YARIYOL KAHRAMANI!";
    } else if (progress < 1.0) {
      titleText += "ÇOK AZ KALDI!";
    } else {
      titleText += "HEDEF TAMAMLANDI!";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Large background decorative icon
          Positioned(
            right: -20,
            top: -10,
            child: Text(
              goal.icon.isNotEmpty ? goal.icon : '🎯',
              style: TextStyle(fontSize: 140, color: Colors.white.withValues(alpha: 0.03)),
            ),
          ),
          InkWell(
            onTap: () {
               _showGoalOptions(context, goal);
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _bgColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            goal.icon.isNotEmpty ? goal.icon : '🎯',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'HEDEF: ${DateFormat('MMMM yyyy', 'tr_TR').format(goal.targetDate).toUpperCase()}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _textGrey, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            AppUtils.formatCurrency(goal.currentAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'biriktirildi',
                            style: TextStyle(fontSize: 13, color: _textGrey),
                          ),
                        ],
                      ),
                      Text(
                        AppUtils.formatCurrency(goal.targetAmount),
                        style: const TextStyle(fontSize: 13, color: _textGrey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: _bgColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: (progress.clamp(0.0, 1.0) * 100).toInt(),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: isDone 
                                ? const LinearGradient(colors: [_greenAccent, _greenAccent])
                                : const LinearGradient(colors: [_blueAccent, _purpleAccent]),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 100 - (progress.clamp(0.0, 1.0) * 100).toInt(),
                          child: const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(isDone ? Icons.check_circle : Icons.emoji_events, color: _greenAccent, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            titleText,
                            style: const TextStyle(color: _greenAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                          ),
                        ],
                      ),
                      Text(
                        '%${(progress * 100).toStringAsFixed(1).replaceAll('.0', '')} Tamamlandı',
                        style: const TextStyle(color: _textGrey, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBudget(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => const AddBudgetModal(),
    );
  }

  void _showAddGoal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => const AddGoalModal(),
    );
  }

  void _showGoalOptions(BuildContext context, Goal goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: _textGrey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            if (!goal.isCompleted)
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: _blueAccent),
                title: const Text('Para Biriktir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _showDepositDialog(context, goal);
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text('Düzenle', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (c) => AddGoalModal(goal: goal),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: _redAccent),
              title: const Text('Sil', style: TextStyle(color: _redAccent)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteGoal(context, goal);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDepositDialog(BuildContext context, Goal goal) {
    // Basic port to keep functionality
    final amountController = TextEditingController();
    String? selectedAccountId;
    final currentAccounts = ref.read(accountProvider).where((acc) => acc.type != 'investment').toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: _cardColor,
          title: Text('${goal.title} İçin Birikim Yap', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Tutar',
                  labelStyle: const TextStyle(color: _textGrey),
                  prefixText: '₺ ',
                  prefixStyle: const TextStyle(color: Colors.white),
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: _textGrey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _textGrey.withValues(alpha: 0.3))),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedAccountId,
                dropdownColor: _cardColor,
                items: currentAccounts.map((acc) => DropdownMenuItem(
                  value: acc.id,
                  child: Text('${acc.name} (${AppUtils.formatCurrency(acc.balance, currency: acc.currency)})', style: const TextStyle(color: Colors.white)),
                )).toList(),
                onChanged: (val) => setState(() => selectedAccountId = val),
                decoration: InputDecoration(
                  labelText: 'Hangi Hesaptan?',
                  labelStyle: const TextStyle(color: _textGrey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _textGrey.withValues(alpha: 0.3))),
                ),
                hint: const Text('Hesap Seçiniz', style: TextStyle(color: _textGrey)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal', style: TextStyle(color: _textGrey))),
            ElevatedButton(
              onPressed: () {
                final amount = ThousandsSeparatorInputFormatter.parse(amountController.text);
                if (amount <= 0 || selectedAccountId == null) return;

                final account = currentAccounts.firstWhere((a) => a.id == selectedAccountId);
                if (account.balance < amount) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yetersiz bakiye!')));
                  return;
                }

                // Create a transfer transaction
                final transaction = Transaction(
                  id: AppUtils.generateId(),
                  userId: 'temp_user_id',
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

                ref.read(transactionProvider.notifier).addTransaction(transaction);
                
                Navigator.pop(ctx);

                // Check for completion after a slight delay
                Future.delayed(const Duration(milliseconds: 300), () {
                  final updatedGoals = ref.read(goalProvider);
                  final updatedGoal = updatedGoals.firstWhere((g) => g.id == goal.id);
                  if (updatedGoal.isCompleted) {
                    if (!context.mounted) return;
                    GoalSuccessDialog.show(context, updatedGoal);
                  }
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: _blueAccent),
              child: const Text('Biriktir', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteGoal(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('Hedefi Sil', style: TextStyle(color: Colors.white)),
        content: Text('${goal.title} hedefini silmek istediğinize emin misiniz?', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal', style: TextStyle(color: _textGrey))),
          ElevatedButton(
            onPressed: () {
              ref.read(goalProvider.notifier).deleteGoal(goal.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _redAccent, foregroundColor: Colors.white),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
