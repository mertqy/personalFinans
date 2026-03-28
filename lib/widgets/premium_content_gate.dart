import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/premium_provider.dart';
import '../screens/paywall_screen.dart';

class PremiumContentGate extends ConsumerWidget {
  final Widget child;
  final bool compact;

  const PremiumContentGate({
    super.key, 
    required this.child,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumAsync = ref.watch(isPremiumProvider);
    final isPremium = premiumAsync.whenOrNull(data: (v) => v) ?? false;

    if (isPremium) {
      return child;
    }

    return Stack(
      children: [
        // Blurred Content
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Opacity(
            opacity: 0.5,
            child: child,
          ),
        ),
        
        // Locked Overlay
        Positioned.fill(
          child: Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(compact ? 8 : 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: const Color(0xFFFFD700),
                      size: compact ? 24 : 32,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Bu özellik\nPremium sürümde',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaywallScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B5BF2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Premium\'a Geç', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                  if (compact) ...[
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaywallScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B5BF2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Premium', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
