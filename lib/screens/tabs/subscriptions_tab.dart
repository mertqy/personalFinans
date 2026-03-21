import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/account_provider.dart';
import '../../core/utils.dart';
import '../../widgets/add_subscription_modal.dart';

class SubscriptionsTab extends ConsumerWidget {
  const SubscriptionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(subscriptionProvider);
    final accounts = ref.watch(accountProvider);

    final activeSubscriptions = subscriptions.where((s) => s.isActive).toList();
    final inactiveSubscriptions = subscriptions.where((s) => !s.isActive).toList();

    // Toplam aylık maliyet
    final totalMonthly = activeSubscriptions.fold(0.0, (sum, s) {
      if (s.frequency == 'yearly') return sum + s.amount / 12;
      return sum + s.amount;
    });

    return Scaffold(
      body: subscriptions.isEmpty
          ? _buildEmptyState(context)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Aylık Toplam Kart
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C5CE7).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('Aylık Abonelik Toplamı',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(
                        AppUtils.formatCurrency(totalMonthly, currency: 'TRY'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${activeSubscriptions.length} aktif abonelik',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Aktif Abonelikler
                if (activeSubscriptions.isNotEmpty) ...[
                  Text('Aktif Abonelikler',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...activeSubscriptions.map((sub) => _buildSubscriptionCard(context, ref, sub, accounts)),
                  const SizedBox(height: 20),
                ],

                // Pasif Abonelikler
                if (inactiveSubscriptions.isNotEmpty) ...[
                  Text('Pasif Abonelikler',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 12),
                  ...inactiveSubscriptions.map((sub) => _buildSubscriptionCard(context, ref, sub, accounts, inactive: true)),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.subscriptions_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Henüz abonelik eklemediniz.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showAddModal(context),
            icon: const Icon(Icons.add),
            label: const Text('Abonelik Ekle'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, WidgetRef ref, sub, accounts, {bool inactive = false}) {
    final color = Color(int.parse(sub.color.replaceFirst('#', 'ff'), radix: 16));
    final accountName = accounts.where((a) => a.id == sub.accountId).isNotEmpty
        ? accounts.firstWhere((a) => a.id == sub.accountId).name
        : '—';

    // Bir sonraki ödeme
    final now = DateTime.now();
    final nextBilling = DateTime(now.year, now.month, sub.billingDay);
    final adjustedNext = nextBilling.isBefore(now) ? DateTime(now.year, now.month + 1, sub.billingDay) : nextBilling;
    final daysUntil = adjustedNext.difference(DateTime(now.year, now.month, now.day)).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: inactive ? Colors.grey : color, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // İkon
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: (inactive ? Colors.grey : color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(sub.icon, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 14),

            // Bilgiler
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: inactive ? Colors.grey : null)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(accountName, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(color: Colors.grey[400])),
                      const SizedBox(width: 8),
                      Text(
                        sub.frequency == 'monthly' ? 'Aylık' : 'Yıllık',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (!inactive) ...[
                    const SizedBox(height: 4),
                    Text(
                      daysUntil == 0 ? 'Bugün ödenecek' : '$daysUntil gün sonra',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: daysUntil <= 3 ? Colors.red : Colors.green),
                    ),
                  ],
                ],
              ),
            ),

            // Tutar ve Aksiyon
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppUtils.formatCurrency(sub.amount, currency: 'TRY'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: inactive ? Colors.grey : color),
                ),
                const SizedBox(height: 4),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Text(sub.isActive ? 'Pasife Al' : 'Aktifleştir'),
                      onTap: () => ref.read(subscriptionProvider.notifier).toggleActive(sub.id),
                    ),
                    PopupMenuItem(
                      child: const Text('Düzenle'),
                      onTap: () {
                        Future.delayed(Duration.zero, () {
                          if (!context.mounted) return;
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => AddSubscriptionModal(subscription: sub),
                          );
                        });
                      },
                    ),
                    PopupMenuItem(
                      child: const Text('Sil', style: TextStyle(color: Colors.red)),
                      onTap: () => ref.read(subscriptionProvider.notifier).deleteSubscription(sub.id),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSubscriptionModal(),
    );
  }
}
