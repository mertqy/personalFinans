import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';

import '../core/constants.dart';

class MiniHeatmap extends ConsumerWidget {
  const MiniHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);
    final locationTransactions = transactions
        .where((tx) => tx.locationLat != null && tx.locationLng != null)
        .toList();

    if (locationTransactions.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF141724), // matched dashboard list bg
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 40, color: Color(0xFF6B5BF2)),
              SizedBox(height: 12),
              Text(
                'Lokasyon verisi bulunamadı',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final lastTx = locationTransactions.first;
    final center = LatLng(lastTx.locationLat!, lastTx.locationLng!);

    return Container(
      height: 180,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF141724),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.0,
              backgroundColor: const Color(0xFF141724), // Fallback map background
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.mertqy.personalfinans',
              ),
              MarkerLayer(
                markers: locationTransactions.map((tx) {
                  final category = AppConstants.defaultCategories.firstWhere(
                    (c) => c['id'] == tx.category,
                    orElse: () => {'icon': '📍', 'color': Colors.blue},
                  );
                  Color markerColor =
                      category['color'] as Color? ?? const Color(0xFF6B5BF2);

                  return Marker(
                    point: LatLng(tx.locationLat!, tx.locationLng!),
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft outer pulse ring
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: markerColor.withValues(alpha: 0.15),
                            boxShadow: [
                              BoxShadow(
                                color: markerColor.withValues(alpha: 0.2),
                                blurRadius: 16,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        // Inner solid dot
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: markerColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: markerColor.withValues(alpha: 0.8),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
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
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00D287), // Green dot indicator
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'AKTİF BÖLGELER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
