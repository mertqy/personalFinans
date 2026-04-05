import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../providers/loan_provider.dart';
import '../../providers/debt_provider.dart';
import '../../core/utils.dart';
import '../../widgets/add_loan_modal.dart';
import '../../widgets/add_debt_modal.dart';
import '../../widgets/pay_debt_modal.dart';
import '../../providers/account_provider.dart';
import '../../models/loan.dart';
import '../../models/debt.dart';

class LoansTab extends ConsumerWidget {
  const LoansTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allLoans = ref.watch(loanProvider);
    final activeLoans = allLoans.where((l) => !l.isCompleted).toList();
    final completedLoans = allLoans.where((l) => l.isCompleted).toList();

    final allDebts = ref.watch(debtProvider);
    final activeDebts = allDebts.where((d) => !d.isCompleted).toList();
    final completedDebts = allDebts.where((d) => d.isCompleted).toList();

    Widget body;
    if (allLoans.isEmpty && allDebts.isEmpty) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.real_estate_agent_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Hiç kredi veya borç kaydınız bulunmuyor.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showAddLoan(context, ref, allLoans.length),
                  icon: const Icon(Icons.add),
                  label: const Text('Kredi Ekle'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _showAddDebt(context, ref, allDebts.length),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Borç Ekle'),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // LOANS SECTION
          if (activeLoans.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8, top: 8),
              child: Text(
                'AKTİF KREDİLER',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
            ),
            ...activeLoans.map((loan) => _buildLoanCard(context, ref, loan)),
          ],

          // DEBTS SECTION
          if (activeDebts.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8, top: 16),
              child: Text(
                'AKTİF BORÇLAR',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
            ),
            ...activeDebts.map((debt) => _buildDebtCard(context, ref, debt)),
          ],

          // COMPLETED LOANS
          if (completedLoans.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'TAMAMLANAN KREDİLER',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
            ),
            ...completedLoans.map((loan) => _buildLoanCard(context, ref, loan)),
          ],

          // COMPLETED DEBTS
          if (completedDebts.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'TAMAMLANAN BORÇLAR',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
            ),
            ...completedDebts.map((debt) => _buildDebtCard(context, ref, debt)),
          ],

          // ACTION BUTTONS
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddLoan(context, ref, allLoans.length),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Kredi Ekle'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddDebt(context, ref, allDebts.length),
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Borç Ekle'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: body,
    );
  }

  void _showAddLoan(BuildContext context, WidgetRef ref, int currentCount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => const AddLoanModal(),
    );
  }

  void _showAddDebt(BuildContext context, WidgetRef ref, int currentCount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => const AddDebtModal(),
    );
  }

  Widget _buildLoanCard(BuildContext context, WidgetRef ref, Loan loan) {
    final paidAmount = loan.totalAmount - loan.remainingAmount;
    final progress = paidAmount / (loan.totalAmount == 0 ? 1 : loan.totalAmount);
    final accounts = ref.watch(accountProvider);
    final account = accounts.firstWhereOrNull((a) => a.id == loan.accountId);
    final currency = account?.currency ?? 'TRY';

    return Card(
      elevation: loan.isCompleted ? 0 : 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: loan.isCompleted
            ? BorderSide(color: Colors.grey.withValues(alpha: 0.2))
            : BorderSide.none,
      ),
      child: Opacity(
        opacity: loan.isCompleted ? 0.7 : 1.0,
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
                        backgroundColor: loan.isCompleted
                            ? Colors.grey.withValues(alpha: 0.2)
                            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        child: Icon(
                          loan.isCompleted ? Icons.check_circle_outline : Icons.account_balance,
                          color: loan.isCompleted ? Colors.grey : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loan.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            loan.bank,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (c) => AddLoanModal(loan: loan),
                        );
                      } else if (value == 'delete') {
                        _confirmDeleteLoan(context, ref, loan.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                      const PopupMenuItem(value: 'delete', child: Text('Sil', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kalan Borç', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        AppUtils.formatCurrency(
                          AppUtils.convertToBaseCurrency(loan.remainingAmount, currency, 'TRY'),
                          currency: 'TRY',
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: loan.isCompleted ? Colors.grey : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Toplam: ${AppUtils.formatCurrency(AppUtils.convertToBaseCurrency(loan.totalAmount, currency, 'TRY'), currency: 'TRY')}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  loan.isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              if (!loan.isCompleted) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showLoanPaymentConfirmation(context, ref, loan),
                        child: const Text('Taksit Öde'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showPayAllLoanConfirmation(context, ref, loan),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.withValues(alpha: 0.1),
                          foregroundColor: Colors.orange,
                          elevation: 0,
                        ),
                        child: const Text('Kapat'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, WidgetRef ref, Debt debt) {
    final paidAmount = debt.totalAmount - debt.remainingAmount;
    final progress = paidAmount / (debt.totalAmount == 0 ? 1 : debt.totalAmount);

    return Card(
      elevation: debt.isCompleted ? 0 : 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: debt.isCompleted
            ? BorderSide(color: Colors.grey.withValues(alpha: 0.2))
            : BorderSide.none,
      ),
      child: Opacity(
        opacity: debt.isCompleted ? 0.7 : 1.0,
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
                        backgroundColor: debt.isCompleted
                            ? Colors.grey.withValues(alpha: 0.2)
                            : Colors.indigo.withValues(alpha: 0.2),
                        child: Icon(
                          debt.isCompleted ? Icons.check_circle_outline : Icons.person_outline,
                          color: debt.isCompleted ? Colors.grey : Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            debt.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (debt.creditorName != null)
                            Text(
                              debt.creditorName!,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                        ],
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (c) => AddDebtModal(debt: debt),
                        );
                      } else if (value == 'delete') {
                        _confirmDeleteDebt(context, ref, debt.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                      const PopupMenuItem(value: 'delete', child: Text('Sil', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kalan Borç', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        AppUtils.formatCurrency(debt.remainingAmount, currency: debt.currency),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: debt.isCompleted ? Colors.grey : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Toplam: ${AppUtils.formatCurrency(debt.totalAmount, currency: debt.currency)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  debt.isCompleted ? Colors.green : Colors.indigo,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              if (!debt.isCompleted) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (c) => PayDebtModal(debt: debt),
                          );
                        },
                        child: const Text('Ödeme Yap'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _confirmCompleteDebt(context, ref, debt),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                          foregroundColor: Colors.green,
                          elevation: 0,
                        ),
                        child: const Text('Kapat'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLoanPaymentConfirmation(BuildContext context, WidgetRef ref, Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Taksit Ödemesi'),
        content: Text('${loan.name} için taksit ödemesini onaylıyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              final amount = loan.monthlyPayment;
              // Transaction logic simplified as per plan
              loan.remainingAmount -= amount;
              if (loan.remainingAmount <= 0) {
                loan.remainingAmount = 0;
                loan.isCompleted = true;
              }
              loan.updatedAt = DateTime.now();
              ref.read(loanProvider.notifier).updateLoan(loan);
              Navigator.pop(context);
            },
            child: const Text('Öde'),
          ),
        ],
      ),
    );
  }

  void _showPayAllLoanConfirmation(BuildContext context, WidgetRef ref, Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borcu Kapat'),
        content: const Text('Kredinin tamamını ödeyerek kapatmak istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              loan.remainingAmount = 0;
              loan.isCompleted = true;
              loan.updatedAt = DateTime.now();
              ref.read(loanProvider.notifier).updateLoan(loan);
              Navigator.pop(context);
            },
            child: const Text('Borcu Kapat'),
          ),
        ],
      ),
    );
  }

  void _confirmCompleteDebt(BuildContext context, WidgetRef ref, Debt debt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borcu Kapat'),
        content: const Text('Bu borcun tamamının ödendiğini ve borcun kapatıldığını onaylıyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              debt.remainingAmount = 0;
              debt.isCompleted = true;
              debt.updatedAt = DateTime.now();
              ref.read(debtProvider.notifier).updateDebt(debt);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Borcu Kapat'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteLoan(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Krediyi Sil'),
        content: const Text('Bu kredi kaydını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              ref.read(loanProvider.notifier).deleteLoan(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDebt(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borcu Sil'),
        content: const Text('Bu borç kaydını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              ref.read(debtProvider.notifier).deleteDebt(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
