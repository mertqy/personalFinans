import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../app/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/premium_provider.dart';
import '../widgets/auth_modal.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  List<Package> _packages = [];
  bool _isLoading = true;
  bool _isPurchasing = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final service = ref.read(purchaseServiceProvider);
    final packages = await service.getOfferings();
    if (mounted) {
      setState(() {
        _packages = packages;
        _isLoading = false;
        // Default select yearly if available
        _selectedIndex = packages.length > 1 ? 1 : 0;
      });
    }
  }

  Future<void> _purchase() async {
    final user = ref.read(authStateProvider).valueOrNull;

    if (user == null || user.isAnonymous) {
      if (mounted) {
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

    if (_packages.isEmpty) return;
    setState(() => _isPurchasing = true);

    final service = ref.read(purchaseServiceProvider);
    final success = await service.purchasePackage(_packages[_selectedIndex]);

    if (mounted) {
      setState(() => _isPurchasing = false);
      if (success) {
        ref.read(premiumRefreshProvider.notifier).state++;
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _restore() async {
    setState(() => _isPurchasing = true);
    final service = ref.read(purchaseServiceProvider);
    final success = await service.restorePurchases();

    if (mounted) {
      setState(() => _isPurchasing = false);
      if (success) {
        ref.read(premiumRefreshProvider.notifier).state++;
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aktif abonelik bulunamadı.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Close Button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                ),
              ),

              const SizedBox(height: 8),

              // Premium Badge
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.2),
                      AppTheme.accent.withValues(alpha: 0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 48,
                  color: Color(0xFFFFD700),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 20),

              Text(
                'Premium\'a Geç',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),
              Text(
                'Tüm özelliklerin kilidini aç',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),

              const SizedBox(height: 28),

              // Features
              ..._features.map((f) => _FeatureRow(icon: f.$1, text: f.$2)),

              const Spacer(),

              // Package Selection
              if (_isLoading)
                const CircularProgressIndicator(strokeWidth: 2)
              else ...[
                ..._packages.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final pkg = entry.value;
                  final isSelected = _selectedIndex == idx;
                  final isYearly = pkg.packageType == PackageType.annual;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = idx),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.15)
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      isYearly ? 'Yıllık' : 'Aylık',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (isYearly) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFFFD700,
                                          ).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          '%38 İNDİRİM',
                                          style: TextStyle(
                                            color: Color(0xFFFFD700),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pkg.storeProduct.priceString,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 8),

              // Purchase Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isPurchasing ? null : _purchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isPurchasing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Abone Ol',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Restore
              TextButton(
                onPressed: _isPurchasing ? null : _restore,
                child: Text(
                  'Satın Alımları Geri Yükle',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  static const _features = [
    (Icons.block, 'Reklamsız deneyim ve sınırsız kullanım'),
    (Icons.map_rounded, 'Harita özelliği (Harcama lokasyonları)'),
    (Icons.bar_chart_rounded, 'Gelişmiş analitik grafikler'),
    (Icons.picture_as_pdf_rounded, 'Bütçe raporu (PDF) dışa aktar'),
    (Icons.account_balance_wallet, 'Sınırsız hesap ve kart ekleme'),
    (Icons.credit_card, 'Sınırsız kredi ve abonelik takibi'),
  ];
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Text(text, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
