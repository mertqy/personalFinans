import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exchange_rate.dart';
import '../services/currency_service.dart';
import '../services/storage_service.dart';

final exchangeRateProvider = StateNotifierProvider<ExchangeRateNotifier, List<ExchangeRate>>((ref) {
  return ExchangeRateNotifier();
});

class ExchangeRateNotifier extends StateNotifier<List<ExchangeRate>> {
  ExchangeRateNotifier() : super([]) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final storedRates = StorageService.getExchangeRates();
    if (storedRates.isNotEmpty) {
      state = storedRates;
    }
    
    // Veriler boşsa veya 15 dakikadan eskiyse güncelle
    if (storedRates.isEmpty || 
        DateTime.now().difference(storedRates.first.lastUpdated).inMinutes >= 15) {
      updateRates();
    }
  }

  Future<void> updateRates() async {
    try {
      final newRatesMap = await CurrencyService.fetchRates();
      final List<ExchangeRate> newRatesList = newRatesMap.values.toList();
      
      // Hive'a kaydet
      for (var rate in newRatesList) {
        StorageService.updateExchangeRate(rate);
      }
      
      state = newRatesList;
    } catch (e) {
      // Hata sessizce geçiliyor veya ilerde bir logger'a bağlanabilir
    }
  }

  // Manual refresh method for UI
  Future<void> refreshRates() async {
    await updateRates();
  }

  double getRate(String code) {
    try {
      return state.firstWhere((r) => r.code == code).rate;
    } catch (_) {
      // Varsayılan kurlar (fallback)
      // Döviz Çevirimi - Varsayılan Kurlar (Güncel 2024/2025 Yaklaşık Değerleri)
      final Map<String, double> fallbacks = {
        'TRY': 1.0,
        'USD': 32.85,
        'EUR': 35.60,
        'GBP': 41.20,
        'GOLD': 3150.0, // 24 Ayar Gram Altın yaklaşık
      };
      return fallbacks[code] ?? 1.0;
    }
  }
}
