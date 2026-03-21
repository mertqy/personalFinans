import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/exchange_rate.dart';
import '../services/currency_service.dart';
import '../services/storage_service.dart';

final exchangeRateProvider = StateNotifierProvider<ExchangeRateNotifier, List<ExchangeRate>>((ref) {
  return ExchangeRateNotifier();
});

class ExchangeRateNotifier extends StateNotifier<List<ExchangeRate>> {
  ExchangeRateNotifier() : super([]) {
    _loadFromStorage();
    _listenToNetwork();
  }

  void _listenToNetwork() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || 
          results.contains(ConnectivityResult.wifi) || 
          results.contains(ConnectivityResult.ethernet)) {
        // Ağ geldiğinde kurları tekrar güncelle
        updateRates();
      }
    });
  }

  void _loadFromStorage() {
    final storedRates = StorageService.getExchangeRates();
    if (storedRates.isNotEmpty) {
      state = storedRates;
    }
    
    // Veriler boşsa veya 15 dakikadan eskiyse ve çevrimiçiysek güncelle
    if (storedRates.isEmpty || 
        DateTime.now().difference(storedRates.first.lastUpdated).inMinutes >= 15) {
      updateRates();
    }
  }

  Future<void> updateRates() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        // Çevrimdışı isek mevcut State'i (Son alınan veriyi) koruyarak çık
        return;
      }

      final newRatesMap = await CurrencyService.fetchRates();
      final List<ExchangeRate> newRatesList = newRatesMap.values.toList();
      
      // Hive'a kaydet (Ağ yokken okunmak üzere saklanacak)
      for (var rate in newRatesList) {
        StorageService.updateExchangeRate(rate);
      }
      
      state = newRatesList;
    } catch (e) {
      // Hata alınırsa sessizce devam et, uygulama offline moda geçmiş gibi son kur bilgilerini kullanmaya devam eder.
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
