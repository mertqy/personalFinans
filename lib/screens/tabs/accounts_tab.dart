import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/account_provider.dart';
import '../../core/utils.dart';
import '../../core/premium_limits.dart';
import '../../widgets/add_account_modal.dart';
import '../../widgets/premium_gate.dart';
import '../account_detail_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AccountsTab extends ConsumerWidget {
  const AccountsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountProvider);

    return accounts.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Henüz bir hesap eklemediniz.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final allowed = await PremiumGate.check(
                      context: context,
                      ref: ref,
                      currentCount: accounts.length,
                      freeLimit: PremiumLimits.freeAccountLimit,
                    );
                    if (!allowed || !context.mounted) return;
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (c) => const AddAccountModal(),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Hesap Ekle'),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount:
                accounts.length + 1, // +1 for the Add New button at the end
            itemBuilder: (context, index) {
              if (index == accounts.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final allowed = await PremiumGate.check(
                        context: context,
                        ref: ref,
                        currentCount: accounts.length,
                        freeLimit: PremiumLimits.freeAccountLimit,
                      );
                      if (!allowed || !context.mounted) return;
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (c) => const AddAccountModal(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Yeni Hesap Ekle'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                );
              }

              final acc = accounts[index];
              final isPositive = acc.balance >= 0;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Color(
                      int.parse(
                        (acc.color ?? '#64B5F6').replaceFirst('#', 'ff'),
                        radix: 16,
                      ),
                    ).withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AccountDetailScreen(account: acc),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Color(
                            int.parse(
                              (acc.color ?? '#64B5F6').replaceFirst('#', 'ff'),
                              radix: 16,
                            ),
                          ).withValues(alpha: 0.2),
                          child: Icon(
                            AppUtils.getAccountIcon(acc.type),
                            color: Color(
                              int.parse(
                                (acc.color ?? '#64B5F6').replaceFirst(
                                  '#',
                                  'ff',
                                ),
                                radix: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Hero(
                                tag: 'acc_name_${acc.id}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    acc.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                AppUtils.getAccountTypeLabel(acc.type),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Hero(
                              tag: 'acc_balance_${acc.id}',
                              child: Material(
                                color: Colors.transparent,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppUtils.formatCurrency(
                                        AppUtils.convertToBaseCurrency(
                                          acc.balance,
                                          acc.currency,
                                          'TRY',
                                        ),
                                        currency: 'TRY',
                                      ),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isPositive
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    if (acc.currency != 'TRY')
                                      Text(
                                        AppUtils.formatCurrency(
                                          acc.balance,
                                          currency: acc.currency,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                size: 20,
                                color: Colors.grey,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (c) =>
                                        AddAccountModal(account: acc),
                                  );
                                } else if (value == 'delete') {
                                  _confirmDelete(context, ref, acc);
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
                                    'Sil',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fade(duration: 400.ms).slideX(begin: 0.1);
            },
          );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic acc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: Text(
          '${acc.name} hesabını silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(accountProvider.notifier).deleteAccount(acc.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Hesap silindi')));
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
