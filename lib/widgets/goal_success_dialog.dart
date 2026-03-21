import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../core/utils.dart';

class GoalSuccessDialog extends StatelessWidget {
  final Goal goal;
  const GoalSuccessDialog({super.key, required this.goal});

  static void show(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GoalSuccessDialog(goal: goal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🎉',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tebrikler!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            '${goal.title} Hedefine Ulaştın!',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '${AppUtils.formatCurrency(goal.targetAmount)} biriktirerek harika bir iş çıkardın. Hayallerine bir adım daha yaklaştın.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Harika!'),
          ),
        ),
      ],
    );
  }
}
