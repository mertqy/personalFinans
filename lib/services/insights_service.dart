import '../models/transaction.dart';
import '../core/utils.dart';

class InsightsService {
  /// Bu ay vs geçen ay kategori bazlı karşılaştırma yaparak akıllı öneriler üretir.
  static List<Map<String, dynamic>> generateInsights(List<Transaction> transactions) {
    final now = DateTime.now();
    final insights = <Map<String, dynamic>>[];

    // Bu ayın giderleri
    final thisMonthExpenses = transactions.where((t) =>
        t.type == 'expense' && !t.isPlanned &&
        t.date.month == now.month && t.date.year == now.year).toList();

    // Geçen ayın giderleri
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
    final lastMonthExpenses = transactions.where((t) =>
        t.type == 'expense' && !t.isPlanned &&
        t.date.month == lastMonth && t.date.year == lastMonthYear).toList();

    if (lastMonthExpenses.isEmpty) return insights;

    // Kategori bazlı toplam harcamalar
    final thisMonthByCategory = <String, double>{};
    for (final tx in thisMonthExpenses) {
      thisMonthByCategory[tx.category] = (thisMonthByCategory[tx.category] ?? 0) + tx.amount;
    }

    final lastMonthByCategory = <String, double>{};
    for (final tx in lastMonthExpenses) {
      lastMonthByCategory[tx.category] = (lastMonthByCategory[tx.category] ?? 0) + tx.amount;
    }

    // En çok artan kategorileri bul
    for (final entry in thisMonthByCategory.entries) {
      final lastAmount = lastMonthByCategory[entry.key] ?? 0;
      if (lastAmount == 0) continue;

      final changePercent = ((entry.value - lastAmount) / lastAmount * 100).round();

      if (changePercent >= 20) {
        final categoryName = AppUtils.getCategoryName(entry.key);
        final categoryIcon = AppUtils.getCategoryIcon(entry.key);
        insights.add({
          'type': 'increase',
          'icon': categoryIcon,
          'category': categoryName,
          'message': 'Bu ay $categoryName kategorisinde geçen aya göre %$changePercent daha fazla harcadın.',
          'percent': changePercent,
        });
      } else if (changePercent <= -20) {
        final categoryName = AppUtils.getCategoryName(entry.key);
        final categoryIcon = AppUtils.getCategoryIcon(entry.key);
        insights.add({
          'type': 'decrease',
          'icon': categoryIcon,
          'category': categoryName,
          'message': 'Bu ay $categoryName harcamalarını %${changePercent.abs()} azalttın. Harika! 🎉',
          'percent': changePercent,
        });
      }
    }

    // En fazla artışa göre sırala
    insights.sort((a, b) => (b['percent'] as int).abs().compareTo((a['percent'] as int).abs()));

    return insights.take(3).toList(); // En önemli 3 öneri
  }

  /// Ay sonu bakiye tahmini hesaplar
  static double calculateEndOfMonthForecast({
    required double currentBalance,
    required List<Transaction> transactions,
  }) {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0); // Ayın son günü

    // Kalan planlanan gelirler (bugünden ay sonuna kadar)
    final remainingPlannedIncome = transactions
        .where((t) => t.isPlanned && t.type == 'income' &&
            t.date.isAfter(now) && !t.date.isAfter(endOfMonth))
        .fold(0.0, (sum, t) => sum + t.amount);

    // Kalan planlanan giderler (bugünden ay sonuna kadar)
    final remainingPlannedExpense = transactions
        .where((t) => t.isPlanned && t.type == 'expense' &&
            t.date.isAfter(now) && !t.date.isAfter(endOfMonth))
        .fold(0.0, (sum, t) => sum + t.amount);

    return currentBalance + remainingPlannedIncome - remainingPlannedExpense;
  }
}
