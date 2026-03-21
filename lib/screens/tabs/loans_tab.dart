import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/loan_provider.dart';
import '../../core/utils.dart';
import '../../widgets/add_loan_modal.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction.dart';

class LoansTab extends ConsumerWidget {
  const LoansTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loans = ref.watch(loanProvider);

    return loans.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.real_estate_agent_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Hiç kredi kaydınız bulunmuyor.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (c) => const AddLoanModal());
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Kredi Ekle'),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: loans.length + 1,
            itemBuilder: (context, index) {
              if (index == loans.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (c) => const AddLoanModal());
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Yeni Kredi Ekle'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                );
              }

              final loan = loans[index];
              final paidAmount = loan.totalAmount - loan.remainingAmount;
              final progress = paidAmount / (loan.totalAmount == 0 ? 1 : loan.totalAmount);

              return Card(
                elevation: 2,
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
                              CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                child: Icon(Icons.account_balance, color: Theme.of(context).colorScheme.primary),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(loan.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(loan.bank, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  const Text('Kalan Borç', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(width: 4),
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
                                        _confirmDelete(context, ref, loan);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                                      const PopupMenuItem(value: 'delete', child: Text('Sil', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                ],
                              ),
                              Text(AppUtils.formatCurrency(loan.remainingAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ödenen: ${AppUtils.formatCurrency(paidAmount)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('Toplam: ${AppUtils.formatCurrency(loan.totalAmount)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _showPaymentConfirmation(context, ref, loan),
                          child: Text('Taksit Öde (${AppUtils.formatCurrency(loan.monthlyPayment)})'),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
  }

  void _showPaymentConfirmation(BuildContext context, WidgetRef ref, dynamic loan) {
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
                Navigator.pop(context); // Close confirmation
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

              // 1. İşlem kaydı oluştur (Notifier balances automatically via _applyEffect)
              final tx = Transaction(
                id: AppUtils.generateId(),
                userId: 'temp_user_id',
                type: 'expense',
                amount: amount,
                category: 'Borç Ödemesi',
                description: '${loan.name} Kredi Taksiti',
                date: DateTime.now(),
                isPlanned: false,
                accountId: loan.accountId,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              ref.read(transactionProvider.notifier).addTransaction(tx);

              // 2. Kredi kalan tutarını güncelle
              loan.remainingAmount -= amount;
              loan.updatedAt = DateTime.now();
              ref.read(loanProvider.notifier).updateLoan(loan);

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Taksit ödemesi başarıyla yapıldı.')),
              );
            },
            child: const Text('Öde'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Krediyi Sil'),
        content: Text('${loan.name} kredisini silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              ref.read(loanProvider.notifier).deleteLoan(loan.id);
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
