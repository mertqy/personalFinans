import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/budget_provider.dart';
import '../../core/utils.dart';
import '../../widgets/add_goal_modal.dart';

class GoalsTab extends ConsumerWidget {
  const GoalsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalProvider);

    return goals.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flag_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Henüz bir birikim hedefi oluşturmadınız.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (c) => const AddGoalModal(),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Hedef Ekle'),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length + 1,
            itemBuilder: (context, index) {
              if (index == goals.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (c) => const AddGoalModal(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Yeni Hedef Ekle'),
                  ),
                );
              }

              final goal = goals[index];
              final progress = goal.currentAmount / (goal.targetAmount == 0 ? 1 : goal.targetAmount);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Color(int.parse((goal.levelColor.isEmpty ? '#64B5F6' : goal.levelColor).replaceFirst('#', 'ff'), radix: 16)).withValues(alpha: 0.2),
                                child: Icon(Icons.savings, color: Color(int.parse((goal.levelColor.isEmpty ? '#64B5F6' : goal.levelColor).replaceFirst('#', 'ff'), radix: 16))),
                              ),
                              const SizedBox(width: 12),
                              Text(goal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          Text(
                            AppUtils.formatCurrency(goal.targetAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progress > 1.0 ? 1.0 : progress,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(Color(int.parse((goal.levelColor.isEmpty ? '#64B5F6' : goal.levelColor).replaceFirst('#', 'ff'), radix: 16))),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${AppUtils.formatCurrency(goal.currentAmount)} birikti', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('%${NumberFormat('##0.0', 'tr_TR').format(progress * 100)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
