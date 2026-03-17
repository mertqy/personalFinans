import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/loan_provider.dart';
import '../../core/utils.dart';
import '../../widgets/add_loan_modal.dart';

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
                              const Text('Kalan Borç', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                          onPressed: () {
                            // Taksit öde
                          },
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
}
