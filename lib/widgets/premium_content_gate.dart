import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return child;
  }
}
