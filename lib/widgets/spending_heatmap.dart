import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/credit_card.dart';

class SpendingHeatmap extends ConsumerWidget {
  final List<Transaction> filteredTransactions;
  final List<Account> accounts;
  final List<CreditCard> creditCards;

  const SpendingHeatmap({
    super.key,
    required this.filteredTransactions,
    required this.accounts,
    required this.creditCards,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only expense transactions from the already filtered set
    final expenses = filteredTransactions
        .where((t) => t.type == 'expense')
        .toList();

    // Determine the current month dates
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    final lastDayOfMonth = DateTime(currentYear, currentMonth + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstDayOfMonth = DateTime(currentYear, currentMonth, 1);
    final firstWeekday = firstDayOfMonth.weekday; // 1 (Mon) to 7 (Sun)

    final totalWeeks = ((daysInMonth + firstWeekday - 2) ~/ 7) + 1;

    // Initialize data structure: 7 rows (days) x totalWeeks columns
    List<List<double>> heatmapData = List.generate(
      7,
      (_) => List.filled(totalWeeks, 0.0),
    );
    double maxAmount = 0.0;

    for (var tx in expenses) {
      if (tx.date.year == currentYear && tx.date.month == currentMonth) {
        int d = tx.date.day;
        int weekIndex = (d + firstWeekday - 2) ~/ 7;
        int weekdayIndex = tx.date.weekday - 1; // 0 for Mon, 6 for Sun

        final displayAmount = AppUtils.getDisplayTRYAmount(
          tx,
          accounts,
          creditCards,
        );
        heatmapData[weekdayIndex][weekIndex] += displayAmount;
        if (heatmapData[weekdayIndex][weekIndex] > maxAmount) {
          maxAmount = heatmapData[weekdayIndex][weekIndex];
        }
      }
    }

    Color getColorForDensity(double amount) {
      if (amount == 0 || maxAmount == 0) return const Color(0xFF242B50);
      final ratio = amount / maxAmount;
      if (ratio <= 0.33) return const Color(0xFF3730A3);
      if (ratio <= 0.66) return const Color(0xFFA5B4FC);
      return const Color(0xFFC7D2FE);
    }

    bool isValidDay(int w, int d) {
      int dayNumber = w * 7 + (d + 1) - (firstWeekday - 1);
      return dayNumber >= 1 && dayNumber <= daysInMonth;
    }

    final dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final monthNames = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141724),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Harcama Yoğunluğu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${monthNames[currentMonth]} Takvimi',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Y-axis labels (Days)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    return Container(
                      height: 18,
                      margin: const EdgeInsets.only(bottom: 6),
                      alignment: Alignment.centerRight,
                      child: Text(
                        index % 2 == 0 ? dayLabels[index] : '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 8),
                // Heatmap Grid
                Row(
                  children: List.generate(totalWeeks, (weekIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Column(
                        children: List.generate(7, (dayIndex) {
                          bool valid = isValidDay(weekIndex, dayIndex);
                          return Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: valid
                                  ? getColorForDensity(
                                      heatmapData[dayIndex][weekIndex],
                                    )
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: valid
                                  ? null
                                  : Border.all(color: Colors.transparent),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Az',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 8),
              _buildLegendNode(const Color(0xFF242B50)),
              const SizedBox(width: 4),
              _buildLegendNode(const Color(0xFF3730A3)),
              const SizedBox(width: 4),
              _buildLegendNode(const Color(0xFFA5B4FC)),
              const SizedBox(width: 4),
              _buildLegendNode(const Color(0xFFC7D2FE)),
              const SizedBox(width: 8),
              Text(
                'Çok',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendNode(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
