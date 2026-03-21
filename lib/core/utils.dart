import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'constants.dart';
import '../models/exchange_rate.dart';

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
      'GOLD': 'gr',
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

  // Döviz Çevirimi - Varsayılan Kurlar (Güncel 2024/2025 Yaklaşık Değerleri)
  static const Map<String, double> exchangeRates = {
    'TRY': 1.0,
    'USD': 32.85,
    'EUR': 35.60,
    'GBP': 41.20,
    'GOLD': 3150.0, // 24 Ayar Gram Altın
  };

  static double convertToBaseCurrency(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    
    // Canlı kurları Hive'dan almayı dene
    Box<ExchangeRate>? rateBox;
    try {
      rateBox = Hive.box<ExchangeRate>('exchange_rates');
    } catch (_) {}

    double getRate(String code) {
      if (code == 'TRY') return 1.0;
      if (rateBox != null && rateBox.containsKey(code)) {
        return rateBox.get(code)!.rate;
      }
      return exchangeRates[code] ?? 1.0;
    }

    final fromRate = getRate(fromCurrency);
    final toRate = getRate(toCurrency);
    
    final amountInTry = amount * fromRate;
    return amountInTry / toRate;
  }

  static Map<String, dynamic>? getCategoryById(String id) {
    try {
      return AppConstants.defaultCategories.firstWhere((c) => c['id'] == id);
    } catch (_) {
      // Eğer ID bulunamazsa, belki isim olarak kaydedilmiştir (Legacy support)
      try {
        return AppConstants.defaultCategories.firstWhere((c) => c['name'] == id);
      } catch (_) {
        return null;
      }
    }
  }

  static String getCategoryName(String categoryId) {
    final cat = getCategoryById(categoryId);
    return cat != null ? cat['name'] as String : categoryId;
  }

  static String getCategoryIcon(String categoryId) {
    final cat = getCategoryById(categoryId);
    return cat != null ? cat['icon'] as String : '❓';
  }

  static String getAccountTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'cash': return 'Nakit';
      case 'bank': return 'Banka';
      case 'savings': return 'Birikim';
      case 'investment': return 'Yatırım';
      default: return type[0].toUpperCase() + type.substring(1);
    }
  }
}
