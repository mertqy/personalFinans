import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/premium_provider.dart';
import '../widgets/auth_modal.dart';
import '../screens/paywall_screen.dart';

class MembershipModal extends ConsumerStatefulWidget {
  const MembershipModal({super.key});

  @override
  ConsumerState<MembershipModal> createState() => _MembershipModalState();
}

class _MembershipModalState extends ConsumerState<MembershipModal> {
  bool _isLoading = false;

  Future<void> _startDirectPayment() async {
    final user = ref.read(authStateProvider).valueOrNull;

    if (user == null || user.isAnonymous) {
      if (mounted) {
        // Close current modal first to avoid overlay issues or show on top
        // Let's show on top
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => const AuthModal(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium almak için lütfen giriş yapın.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    final purchaseService = ref.read(purchaseServiceProvider);
// ... existing code ...

    try {
      final packages = await purchaseService.getOfferings();
      if (packages.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paketler yüklenemedi. Lütfen tekrar deneyin.')),
          );
        }
        return;
      }

      // Try to find Annual first, then first available
      final annual = packages.where((p) => p.packageType == PackageType.annual).firstOrNull;
      final packageToBuy = annual ?? packages.first;

      final success = await purchaseService.purchasePackage(packageToBuy);
      
      if (mounted) {
        if (success) {
          ref.read(premiumRefreshProvider.notifier).state++;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Premium üyeliğiniz aktif edildi!')),
          );
        } else {
          // If failed or cancelled, navigate to Paywall Screen so they can choose
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PaywallScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sistem hatası: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider).valueOrNull ?? false;

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF141724),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Üyeliğim',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Current Membership Status
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: isPremium
                  ? const LinearGradient(
                      colors: [Color(0xFF6B5BF2), Color(0xFF5A49F2)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF202334), Color(0xFF1C2235)],
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mevcut Plan',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPremium ? 'Premium Plan' : 'Normal Sürüm',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Plan Karşılaştırması',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              const Expanded(flex: 3, child: SizedBox()),
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    'Normal',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    'Premium',
                    style: TextStyle(
                      color: Color(0xFF6B5BF2),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),

          _buildComparisonRow('Reklamsız Deneyim', false, true),
          _buildComparisonRow('Harcama Haritası', false, true),
          _buildComparisonRow('Gelişmiş Grafik Analizleri', false, true),
          _buildComparisonRow('Bütçe Raporu (PDF)', false, true),
          _buildComparisonRow('Sınırsız Hesap ve Kart', false, true),
          _buildComparisonRow('Sınırsız Kredi ve Abonelik', false, true),
          _buildComparisonRow('Sınırsız Bütçe Hedefi', false, true),
          _buildComparisonRow('Temel Finans Takibi', true, true),

          const SizedBox(height: 24),

          if (!isPremium)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startDirectPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B5BF2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Premium\'a Geç',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String feature, bool normalHas, bool premiumHas) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Icon(
                normalHas ? Icons.check_circle : Icons.cancel,
                color: normalHas ? const Color(0xFF00D287) : Colors.white24,
                size: 20,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Icon(
                premiumHas ? Icons.check_circle : Icons.cancel,
                color: premiumHas ? const Color(0xFF6B5BF2) : Colors.white24,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
