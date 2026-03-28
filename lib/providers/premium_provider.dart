import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/purchase_service.dart';
import '../providers/auth_provider.dart';

final purchaseServiceProvider = Provider<PurchaseService>(
  (ref) => PurchaseService(),
);

final isPremiumProvider = FutureProvider<bool>((ref) async {
  // Suspend premium: Always return true for now
  return true;
});

// Force refresh premium status after a purchase
final premiumRefreshProvider = StateProvider<int>((ref) => 0);
