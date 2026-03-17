import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AppUtils {
  static const Uuid _uuid = Uuid();

  static String generateId() {
    return _uuid.v4();
  }

  static String formatCurrency(double amount, {String currency = 'TRY'}) {
    final Map<String, String> currencySymbols = {
      'TRY': '₺',
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'GOLD': 'Au',
    };

    final symbol = currencySymbols[currency] ?? '₺';
    
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: symbol,
      decimalDigits: 2,
    );
    
    return formatter.format(amount);
  }

  static String formatDate(DateTime date, {bool short = false}) {
    final format = short ? 'dd/MM/yyyy' : 'dd MMMM yyyy';
    return DateFormat(format, 'tr_TR').format(date);
  }

  // Döviz Çevirimi - Varsayılan Kurlar (Gerçek uygulamada API'den çekilebilir)
  static const Map<String, double> exchangeRates = {
    'TRY': 1.0,
    'USD': 32.5,
    'EUR': 35.2,
    'GBP': 41.0,
    'GOLD': 2500.0, 
  };

  static double convertToBaseCurrency(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    
    final fromRate = exchangeRates[fromCurrency] ?? 1.0;
    final toRate = exchangeRates[toCurrency] ?? 1.0;
    
    // Önce TRY'ye (baz para birimi) çevir, sonra hedefe
    final amountInTry = amount * fromRate;
    return amountInTry / toRate;
  }
}
