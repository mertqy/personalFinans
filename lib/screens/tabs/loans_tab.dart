import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/loan_provider.dart';
import '../../core/utils.dart';
import '../../widgets/add_loan_modal.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction.dart';
import '../../models/loan.dart';

class LoansTab extends ConsumerWidget {
  const LoansTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allLoans = ref.watch(loanProvider);
    final activeLoans = allLoans.where((l) => !l.isCompleted).toList();
    final completedLoans = allLoans.where((l) => l.isCompleted).toList();

    if (allLoans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.real_estate_agent_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Hiç kredi kaydınız bulunmuyor.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context, 
                  isScrollControlled: true, 
                  backgroundColor: Colors.transparent, 
                  builder: (c) => const AddLoanModal()
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Kredi Ekle'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (activeLoans.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Aktif Krediler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...activeLoans.map((loan) => _buildLoanCard(context, ref, loan)),
        ],
        if (completedLoans.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Tamamlanan Krediler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
          ),
          ...completedLoans.map((loan) => _buildLoanCard(context, ref, loan)),
        ],
        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }

  Widget _buildLoanCard(BuildContext context, WidgetRef ref, Loan loan) {
    final paidAmount = loan.totalAmount - loan.remainingAmount;
    final progress = paidAmount / (loan.totalAmount == 0 ? 1 : loan.totalAmount);

    return Card(
      elevation: loan.isCompleted ? 0 : 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: loan.isCompleted ? BorderSide(color: Colors.grey.withOpacity(0.2)) : BorderSide.none,
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
                            ? Colors.grey.withOpacity(0.2)
                            : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        child: Icon(
                          loan.isCompleted ? Icons.check_circle_outline : Icons.account_balance, 
                          color: loan.isCompleted ? Colors.grey : Theme.of(context).colorScheme.primary
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(loan.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              if (loan.isCompleted) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('BİTTİ', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          Text(loan.bank, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (value) {
                      if (value == 'edit') {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (c) => AddLoanModal(loan: loan),
                        );
                      } else if (value == 'delete') {
                        _confirmDelete(context, ref, loan.id);
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
                      Text(AppUtils.formatCurrency(loan.remainingAmount), 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 18, 
                          color: loan.isCompleted ? Colors.grey : Colors.orange
                        )
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Ödenen: ${AppUtils.formatCurrency(paidAmount)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('Toplam: ${AppUtils.formatCurrency(loan.totalAmount)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  loan.isCompleted ? Colors.green : Theme.of(context).colorScheme.primary
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: loan.isCompleted ? null : () => _showPaymentConfirmation(context, ref, loan),
                      child: Text(loan.isCompleted ? 'Borç Kapandı' : 'Taksit Öde (${AppUtils.formatCurrency(loan.monthlyPayment)})'),
                    ),
                  ),
                  if (!loan.isCompleted) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showPayAllConfirmation(context, ref, loan),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          foregroundColor: Colors.orange,
                          elevation: 0,
                          side: const BorderSide(color: Colors.orange, width: 0.5),
                        ),
                        child: const Text('Borcu Kapat'),
                      ),
                    ),
                  ],
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentConfirmation(BuildContext context, WidgetRef ref, Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Taksit Ödemesi'),
        content: Text('${loan.name} için ${AppUtils.formatCurrency(loan.monthlyPayment)} tutarındaki taksit ödemesini onaylıyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              final amount = loan.monthlyPayment;
              final accounts = ref.read(accountProvider);
              final account = accounts.where((a) => a.id == loan.accountId).firstOrNull;

              if (account != null && account.balance < amount) {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Yetersiz Bakiye'),
                      ],
                    ),
                    content: Text('${account.name} hesabında bu ödeme için yeterli bakiye bulunmuyor.\n\nEksik olan tutar: ${AppUtils.formatCurrency(amount - account.balance)}'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anladım')),
                    ],
                  ),
                );
                return;
              }

              final tx = Transaction(
                id: AppUtils.generateId(),
                userId: 'temp_user_id',
                type: 'expense',
                amount: amount,
                category: 'Taksit Ödemesi',
                description: '${loan.name} Kredi Taksiti',
                date: DateTime.now(),
                isPlanned: false,
                accountId: loan.accountId,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              ref.read(transactionProvider.notifier).addTransaction(tx);

              loan.remainingAmount -= amount;
              if (loan.remainingAmount <= 0) {
                loan.remainingAmount = 0;
                loan.isCompleted = true;
              }
              loan.updatedAt = DateTime.now();
              ref.read(loanProvider.notifier).updateLoan(loan);

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loan.isCompleted ? 'Kredi başarıyla tamamlandı!' : 'Taksit ödemesi başarıyla yapıldı.')),
              );
            },
            child: const Text('Öde'),
          ),
        ],
      ),
    );
  }

  void _showPayAllConfirmation(BuildContext context, WidgetRef ref, Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borcu Kapat'),
        content: Text('${loan.name} borcunun tamamını (${AppUtils.formatCurrency(loan.remainingAmount)}) ödeyerek krediyi kapatmak istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              final amount = loan.remainingAmount;
              final accounts = ref.read(accountProvider);
              final account = accounts.where((a) => a.id == loan.accountId).firstOrNull;

              if (account != null && account.balance < amount) {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Yetersiz Bakiye'),
                      ],
                    ),
                    content: Text('${account.name} hesabında bu ödeme için yeterli bakiye bulunmuyor.\n\nEksik olan tutar: ${AppUtils.formatCurrency(amount - account.balance)}'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anladım')),
                    ],
                  ),
                );
                return;
              }

              final tx = Transaction(
                id: AppUtils.generateId(),
                userId: 'temp_user_id',
                type: 'expense',
                amount: amount,
                category: 'Borç Kapatma',
                description: '${loan.name} Borç Kapatma',
                date: DateTime.now(),
                isPlanned: false,
                accountId: loan.accountId,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              ref.read(transactionProvider.notifier).addTransaction(tx);

              loan.remainingAmount = 0;
              loan.isCompleted = true;
              loan.updatedAt = DateTime.now();
              ref.read(loanProvider.notifier).updateLoan(loan);

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kredi borcu başarıyla kapatıldı.')),
              );
            },
            child: const Text('Borcu Kapat'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Krediyi Sil'),
        content: const Text('Bu krediyi silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              ref.read(loanProvider.notifier).deleteLoan(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kredi silindi')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
