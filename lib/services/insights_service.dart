import '../models/transaction.dart';
import '../core/utils.dart';

class InsightsService {
  /// Bu ay vs geçen ay kategori bazlı karşılaştırma yaparak akıllı öneriler üretir.
  static List<Map<String, dynamic>> generateInsights(
    List<Transaction> transactions,
  ) {
    final now = DateTime.now();
    final insights = <Map<String, dynamic>>[];

    // Bu ayın giderleri
    final thisMonthExpenses = transactions
        .where(
          (t) =>
              t.type == 'expense' &&
              !t.isPlanned &&
              t.date.month == now.month &&
              t.date.year == now.year,
        )
        .toList();

    // Geçen ayın giderleri
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
    final lastMonthExpenses = transactions
        .where(
          (t) =>
              t.type == 'expense' &&
              !t.isPlanned &&
              t.date.month == lastMonth &&
              t.date.year == lastMonthYear,
        )
        .toList();

    if (lastMonthExpenses.isEmpty) return insights;

    // Kategori bazlı toplam harcamalar
    final thisMonthByCategory = <String, double>{};
    for (final tx in thisMonthExpenses) {
      thisMonthByCategory[tx.category] =
          (thisMonthByCategory[tx.category] ?? 0) + tx.amount;
    }

    final lastMonthByCategory = <String, double>{};
    for (final tx in lastMonthExpenses) {
      lastMonthByCategory[tx.category] =
          (lastMonthByCategory[tx.category] ?? 0) + tx.amount;
    }

    // En çok artan kategorileri bul
    for (final entry in thisMonthByCategory.entries) {
      final lastAmount = lastMonthByCategory[entry.key] ?? 0;
      if (lastAmount == 0) continue;

      final changePercent = ((entry.value - lastAmount) / lastAmount * 100)
          .round();

      if (changePercent >= 20) {
        final categoryName = AppUtils.getCategoryName(entry.key);
        final categoryIcon = AppUtils.getCategoryIcon(entry.key);
        insights.add({
          'type': 'increase',
          'icon': categoryIcon,
          'category': categoryName,
          'message':
              'Bu ay $categoryName kategorisinde geçen aya göre %$changePercent daha fazla harcadın.',
          'percent': changePercent,
        });
      } else if (changePercent <= -20) {
        final categoryName = AppUtils.getCategoryName(entry.key);
        final categoryIcon = AppUtils.getCategoryIcon(entry.key);
        insights.add({
          'type': 'decrease',
          'icon': categoryIcon,
          'category': categoryName,
          'message':
              'Bu ay $categoryName harcamalarını %${changePercent.abs()} azalttın. Harika! 🎉',
          'percent': changePercent,
        });
      }
    }

    // En fazla artışa göre sırala
    insights.sort(
      (a, b) =>
          (b['percent'] as int).abs().compareTo((a['percent'] as int).abs()),
    );

    return insights.take(3).toList(); // En önemli 3 öneri
  }

  /// Ay sonu bakiye tahmini hesaplar
  static double calculateEndOfMonthForecast({
    required double currentBalance,
    required List<Transaction> transactions,
    required List<dynamic> subscriptions,
  }) {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0); // Ayın son günü

    double forecast = currentBalance;

    // 1. Kalan planlanan tekil işlemler (isPlanned = true but date is in future)
    final remainingPlanned = transactions.where(
      (t) => t.isPlanned && t.date.isAfter(now) && !t.date.isAfter(endOfMonth),
    );

    for (final tx in remainingPlanned) {
      if (tx.type == 'income') {
        forecast += tx.amount;
      } else if (tx.type == 'expense') {
        forecast -= tx.amount;
      } else if (tx.type == 'transfer' && tx.toGoalId != null) {
        // Hedefe transfer de bakiyeden düşer
        forecast -= tx.amount;
      }
    }

    // 2. Tekrarlanan İşlemler (Templates)
    // En son gerçekleşen non-planned recurring tx'leri bulup bir sonrakileri hesapla
    final recurringTemplates = <String, Transaction>{};
    for (var tx in transactions) {
      if (tx.isRecurring == true &&
          !tx.isPlanned &&
          tx.recurringFrequency != null) {
        final key = '${tx.category}_${tx.description}_${tx.accountId}';
        if (!recurringTemplates.containsKey(key) ||
            tx.date.isAfter(recurringTemplates[key]!.date)) {
          recurringTemplates[key] = tx;
        }
      }
    }

    recurringTemplates.forEach((key, lastTx) {
      DateTime nextOccur = _calculateNextDate(
        lastTx.date,
        lastTx.recurringFrequency!,
      );
      while (!nextOccur.isAfter(endOfMonth)) {
        if (nextOccur.isAfter(now)) {
          if (lastTx.type == 'income') {
            forecast += lastTx.amount;
          } else if (lastTx.type == 'expense') {
            forecast -= lastTx.amount;
          } else if (lastTx.type == 'transfer' && lastTx.toGoalId != null) {
            forecast -= lastTx.amount;
          }
        }
        nextOccur = _calculateNextDate(nextOccur, lastTx.recurringFrequency!);
      }
    });

    // 3. Abonelikler
    for (var sub in subscriptions) {
      if (!sub.isActive) continue;

      DateTime nextOccur;
      if (sub.lastProcessedAt == null) {
        nextOccur = DateTime(
          sub.createdAt.year,
          sub.createdAt.month,
          sub.billingDay,
        );
        if (nextOccur.isBefore(sub.createdAt)) {
          nextOccur = _calculateNextSubscriptionDate(
            nextOccur,
            sub.billingDay,
            sub.frequency,
          );
        }
      } else {
        nextOccur = _calculateNextSubscriptionDate(
          sub.lastProcessedAt!,
          sub.billingDay,
          sub.frequency,
        );
      }

      while (!nextOccur.isAfter(endOfMonth)) {
        if (nextOccur.isAfter(now)) {
          forecast -= sub.amount;
        }
        nextOccur = _calculateNextSubscriptionDate(
          nextOccur,
          sub.billingDay,
          sub.frequency,
        );
      }
    }

    return forecast;
  }

  static DateTime _calculateNextDate(DateTime date, String frequency) {
    switch (frequency) {
      case 'daily':
        return date.add(const Duration(days: 1));
      case 'weekly':
        return date.add(const Duration(days: 7));
      case 'monthly':
        int nextMonth = date.month + 1;
        int nextYear = date.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        int lastDay = DateTime(nextYear, nextMonth + 1, 0).day;
        return DateTime(
          nextYear,
          nextMonth,
          date.day > lastDay ? lastDay : date.day,
        );
      case 'yearly':
        return DateTime(date.year + 1, date.month, date.day);
      default:
        return date.add(const Duration(days: 30));
    }
  }

  static DateTime _calculateNextSubscriptionDate(
    DateTime lastDate,
    int billingDay,
    String frequency,
  ) {
    if (frequency == 'yearly') {
      return DateTime(lastDate.year + 1, lastDate.month, billingDay);
    } else {
      int nextMonth = lastDate.month + 1;
      int nextYear = lastDate.year;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }
      int lastDayOfMonth = DateTime(nextYear, nextMonth + 1, 0).day;
      int day = billingDay > lastDayOfMonth ? lastDayOfMonth : billingDay;
      return DateTime(nextYear, nextMonth, day);
    }
  }
}
