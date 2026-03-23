import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finans/models/subscription.dart';
import 'package:personal_finans/core/utils.dart';
import 'package:personal_finans/core/formatters.dart';

void main() {
  group('Subscription Logic Tests', () {
    test('Should parse amount correctly with thousands separator and decimal', () {
      expect(ThousandsSeparatorInputFormatter.parse("1.250"), 1250.0);
      expect(ThousandsSeparatorInputFormatter.parse("1.250,50"), 1250.50);
      expect(ThousandsSeparatorInputFormatter.parse("0,75"), 0.75);
    });

    test('Should format amount correctly for display', () {
      expect(ThousandsSeparatorInputFormatter.format(1250.0), "1.250");
      // Not: NumberFormat.decimalPattern('tr_TR') bazen ondalık küsurat yoksa virgül koymaz.
      // Ama varsa koymalı.
      expect(ThousandsSeparatorInputFormatter.format(1250.50), contains("1.250"));
      expect(ThousandsSeparatorInputFormatter.format(1250.50), contains("5"));
    });

    test('Should convert currency correctly', () {
      final amountInTry = 1000.0;
      // TRY -> EUR (Rate ~35.6)
      final amountInEur = AppUtils.convertToBaseCurrency(amountInTry, 'TRY', 'EUR');
      expect(amountInEur, closeTo(1000 / 35.6, 0.01));
    });

    test('Should create a Subscription object without errors', () {
      final sub = Subscription(
        id: AppUtils.generateId(),
        userId: 'test_user',
        name: 'Test Sub',
        amount: 25.0,
        category: 'subscription',
        accountId: 'acc_123',
        billingDay: 15,
        frequency: 'monthly',
        isActive: true,
        icon: '📺',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(sub.name, 'Test Sub');
      expect(sub.amount, 25.0);
    });
  });
}
