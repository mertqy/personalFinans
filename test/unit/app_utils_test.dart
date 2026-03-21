import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:personal_finans/core/utils.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR', null);
  });

  group('AppUtils Tests', () {
    test('generateId returns unique UUID', () {
      final id1 = AppUtils.generateId();
      final id2 = AppUtils.generateId();
      
      expect(id1.isNotEmpty, true);
      expect(id2.isNotEmpty, true);
      expect(id1, isNot(equals(id2)));
    });

    test('colorToHex correctly converts Color to hex string', () {
      expect(AppUtils.colorToHex(const Color(0xFF00FF00)), '#00FF00');
      expect(AppUtils.colorToHex(const Color(0xFFFF0000)), '#FF0000');
      expect(AppUtils.colorToHex(const Color(0xFF0000FF)), '#0000FF');
    });

    test('hexToColor correctly converts hex string to Color', () {
      expect(AppUtils.hexToColor('#00FF00'), const Color(0xFF00FF00));
      expect(AppUtils.hexToColor('#FF0000'), const Color(0xFFFF0000));
      expect(AppUtils.hexToColor('#0000FF'), const Color(0xFF0000FF));
      expect(AppUtils.hexToColor('invalid_hex'), Colors.blue); // Fallback color
    });

    test('formatCurrency converts to localized format', () {
      final formatted = AppUtils.formatCurrency(1500.50, currency: 'TRY');
      // Format is locale dependent, generally similar to 1.500,50 ₺ or ₺1.500,50
      expect(formatted.contains('1.500,50') || formatted.contains('1500,50'), true);
      expect(formatted.contains('₺'), true);
    });

    test('getCurrencySymbol returns correct symbol', () {
      expect(AppUtils.getCurrencySymbol('TRY'), '₺');
      expect(AppUtils.getCurrencySymbol('USD'), '\$');
      expect(AppUtils.getCurrencySymbol('EUR'), '€');
      expect(AppUtils.getCurrencySymbol('GBP'), '£');
      expect(AppUtils.getCurrencySymbol('GOLD'), 'gr');
      expect(AppUtils.getCurrencySymbol('UNKNOWN'), '₺'); // Fallback
    });

    test('formatDate returns correctly formatted string', () {
      final date = DateTime(2025, 4, 15);
      expect(AppUtils.formatDate(date, short: true), '15/04/2025');
      // Note: 'dd MMMM yyyy' in tr_TR will be '15 Nisan 2025'
      expect(AppUtils.formatDate(date, short: false), '15 Nisan 2025');
    });

    test('convertToBaseCurrency correctly applies exchange rates', () {
      // 1 USD is 32.85 TRY, 1 EUR is 35.60 TRY (from constants)
      
      // USD to TRY
      final tryAmount = AppUtils.convertToBaseCurrency(100, 'USD', 'TRY');
      expect(tryAmount, 3285.0);

      // EUR to TRY
      final tryFromEur = AppUtils.convertToBaseCurrency(100, 'EUR', 'TRY');
      expect(tryFromEur, 3560.0);

      // USD to EUR
      final eurAmount = AppUtils.convertToBaseCurrency(100, 'USD', 'EUR');
      expect(eurAmount, (100 * 32.85) / 35.60);

      // Same currency
      final sameAmount = AppUtils.convertToBaseCurrency(100, 'USD', 'USD');
      expect(sameAmount, 100.0);
    });
  });
}
