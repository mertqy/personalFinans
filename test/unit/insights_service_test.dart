import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finans/models/transaction.dart';
import 'package:personal_finans/models/subscription.dart';
import 'package:personal_finans/services/insights_service.dart';

void main() {
  group('InsightsService Tests', () {
    test('calculateEndOfMonthForecast includes planned transactions', () {
      final now = DateTime.now();

      final currentBalance = 1000.0;

      final transactions = [
        // Income planned before end of month
        Transaction(
          id: '1',
          userId: 'u1',
          type: 'income',
          amount: 500,
          category: 'Maaş',
          description: 'Maaş',
          date: now.add(const Duration(days: 2)),
          isPlanned: true,
          accountId: 'a1',
          createdAt: now,
          updatedAt: now,
        ),
        // Expense planned before end of month
        Transaction(
          id: '2',
          userId: 'u1',
          type: 'expense',
          amount: 200,
          category: 'Fatura',
          description: 'Elektrik',
          date: now.add(const Duration(days: 4)),
          isPlanned: true,
          accountId: 'a1',
          createdAt: now,
          updatedAt: now,
        ),
        // Planned income FOR NEXT MONTH (should not be included)
        Transaction(
          id: '3',
          userId: 'u1',
          type: 'income',
          amount: 1000,
          category: 'Harçlık',
          description: 'Harçlık',
          date: DateTime(now.year, now.month + 1, 5),
          isPlanned: true,
          accountId: 'a1',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final forecast = InsightsService.calculateEndOfMonthForecast(
        currentBalance: currentBalance,
        transactions: transactions,
        subscriptions: [],
      );

      // 1000 + 500 - 200 = 1300
      expect(forecast, 1300.0);
    });

    test('calculateEndOfMonthForecast calculates recurring transactions', () {
      final now = DateTime.now();
      final currentBalance = 1000.0;

      final transactions = [
        // A weekly recurring expense that happened earlier this month
        Transaction(
          id: '1',
          userId: 'u1',
          type: 'expense',
          amount: 100,
          category: 'Market',
          description: 'Market Alışverişi',
          date: DateTime(now.year, now.month, 1),
          isPlanned: false,
          isRecurring: true,
          recurringFrequency: 'weekly',
          accountId: 'a1',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final forecast = InsightsService.calculateEndOfMonthForecast(
        currentBalance: currentBalance,
        transactions: transactions,
        subscriptions: [],
      );

      // Depending on how many weeks left in the month from today, it should deduct 100 for each week
      // Since `now` is dynamic, logic verification is more about whether it subtracts correctly.
      expect(forecast < 1000.0, true);
    });

    test('calculateEndOfMonthForecast calculates subscriptions', () {
      final now = DateTime.now();
      final currentBalance = 1000.0;

      // Let's assume today is the 10th of the month
      final billingDay = 25; // A subscription billed on the 25th of every month

      final subscriptions = [
        Subscription(
          id: '1',
          userId: 'u1',
          name: 'Netflix',
          amount: 200,
          category: 'Eğlence',
          accountId: 'a1',
          billingDay: billingDay,
          frequency: 'monthly',
          isActive: true,
          icon: 'netflix',
          color: '#ff0000',
          createdAt: DateTime(now.year, now.month - 1, 5),
          updatedAt: now,
          lastProcessedAt: DateTime(
            now.year,
            now.month - 1,
            billingDay,
          ), // Last billed last month
        ),
      ];

      final transactions = <Transaction>[];

      final forecast = InsightsService.calculateEndOfMonthForecast(
        currentBalance: currentBalance,
        transactions: transactions,
        subscriptions: subscriptions,
      );

      // If today is before the 25th, it should deduct 200. If today is after the 25th, it already passed.
      // So we test dynamically.
      if (now.day < billingDay) {
        expect(forecast, 800.0);
      } else {
        expect(forecast, 1000.0); // Already happened this month
      }
    });
  });
}
