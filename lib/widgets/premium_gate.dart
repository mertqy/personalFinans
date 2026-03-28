import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/premium_provider.dart';
import '../screens/paywall_screen.dart';

/// Wrapper widget that checks premium limits before allowing an action.
/// Shows paywall if the user exceeds the free tier limit.
class PremiumGate {
  /// Check if the user can perform the action. If not, show paywall.
  /// Returns true if allowed, false if blocked.
  static Future<bool> check({
    required BuildContext context,
    required WidgetRef ref,
    required int currentCount,
    required int freeLimit,
  }) async {
    final premiumAsync = ref.read(isPremiumProvider);
    final isPremium = premiumAsync.whenOrNull(data: (v) => v) ?? false;

    if (isPremium || currentCount < freeLimit) {
      return true;
    }

    // Show paywall
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const PaywallScreen()));

    return result == true;
  }
}
