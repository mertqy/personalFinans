import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../core/constants.dart';
import '../core/utils.dart';

class MiniHeatmap extends ConsumerWidget {
  const MiniHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);
    final accounts = ref.watch(accountProvider);
    final locationTransactions = transactions.where((tx) => tx.locationLat != null && tx.locationLng != null).toList();

    if (locationTransactions.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('Henüz konum verisi yok', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Harita merkezini son harcamaya göre ayarla
    final lastTx = locationTransactions.first;
    final center = LatLng(lastTx.locationLat!, lastTx.locationLng!);

    return Container(
      height: 250,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.0,
              interactionOptions: const InteractionOptions(
                 flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mertqy.personalfinans',
              ),
              MarkerLayer(
                markers: locationTransactions.map((tx) {
                  // Kategori ikonunu bul
                  final category = AppConstants.defaultCategories.firstWhere(
                    (c) => c['id'] == tx.category,
                    orElse: () => {'icon': '💰', 'color': Colors.blue},
                  );
                  
                  // Hesabı bulup para birimini al
                  final account = accounts.any((a) => a.id == tx.accountId) 
                    ? accounts.firstWhere((a) => a.id == tx.accountId) 
                    : null;
                  final currency = account?.currency ?? '₺';
                  
                  return Marker(
                    point: LatLng(tx.locationLat!, tx.locationLng!),
                    width: 60,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            AppUtils.formatCurrency(tx.amount, currency: currency),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: (category['color'] as Color).withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Center(
                            child: Text(category['icon'] as String, style: const TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map, size: 16, color: Colors.blue),
                  SizedBox(width: 6),
                  Text(
                    'Harcama Haritası',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
