import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/credit_card_provider.dart';
import '../../core/utils.dart';
import '../../widgets/add_card_modal.dart';

class CardsTab extends ConsumerWidget {
  const CardsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(creditCardProvider);

    return cards.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.credit_card_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Henüz bir kredi kartı eklemediniz.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (c) => const AddCardModal());
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Kart Ekle'),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length + 1,
            itemBuilder: (context, index) {
              if (index == cards.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (c) => const AddCardModal());
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Yeni Kart Ekle'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                );
              }

              final card = cards[index];
              final availableLimit = card.limit - card.currentDebt;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(int.parse(card.color.replaceFirst('#', 'ff'), radix: 16)),
                      Color(int.parse(card.color.replaceFirst('#', 'ff'), radix: 16)).withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(int.parse(card.color.replaceFirst('#', 'ff'), radix: 16)).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(card.bank, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            const Icon(Icons.credit_card, color: Colors.white),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20, color: Colors.white70),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (c) => AddCardModal(card: card),
                                  );
                                } else if (value == 'delete') {
                                  _confirmDelete(context, ref, card);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                                const PopupMenuItem(value: 'delete', child: Text('Sil', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(card.name, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Limit', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            Text(AppUtils.formatCurrency(card.limit), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Güncel Borç', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            Text(AppUtils.formatCurrency(card.currentDebt), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: card.currentDebt / (card.limit == 0 ? 1 : card.limit),
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text('Kullanılabilir: ${AppUtils.formatCurrency(availableLimit)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              );
            },
          );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kartı Sil'),
        content: Text('${card.name} kartını silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              ref.read(creditCardProvider.notifier).deleteCard(card.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kart silindi')),
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
