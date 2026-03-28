import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/exchange_rate.dart';

class CurrencyService {
  // Truncgil V4 en güncel sürümdür
  static const String apiUrl = 'https://finans.truncgil.com/v4/today.json';

  static Future<Map<String, ExchangeRate>> fetchRates() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl?t=${DateTime.now().millisecondsSinceEpoch}'),
      );
      if (response.statusCode == 200) {
        // UTF-8 decode
        final String body = utf8.decode(response.bodyBytes);
        final data = json.decode(body) as Map<String, dynamic>;
        final now = DateTime.now();
        final Map<String, ExchangeRate> rates = {};

        // Desteklediğimiz birimler ve API'deki karşılıkları
        final targetMapping = {
          'USD': 'USD',
          'EUR': 'EUR',
          'GBP': 'GBP',
          'GOLD': 'GRA', // Gram Altın (Piyasa değeri)
        };

        targetMapping.forEach((code, apiKey) {
          if (data.containsKey(apiKey)) {
            final node = data[apiKey];
            String? rawValue;

            if (node is Map) {
              // V4 uses "Selling", V3 used "satis" or "Satış"
              rawValue = (node['Selling'] ?? node['satis'] ?? node['Satış'])
                  ?.toString();
            }

            if (rawValue != null) {
              final rate = _parseCurrencyValue(rawValue);
              if (rate != null) {
                rates[code] = ExchangeRate(
                  code: code,
                  rate: rate,
                  lastUpdated: now,
                );
              }
            }
          }
        });

        // TRY her zaman 1.0
        rates['TRY'] = ExchangeRate(code: 'TRY', rate: 1.0, lastUpdated: now);

        return rates;
      } else {
        throw Exception('Kurlar alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('CurrencyService Error: $e');
      rethrow;
    }
  }

  /// API'den gelen sayıları double'a çevirir.
  static double? _parseCurrencyValue(String value) {
    try {
      // Eğer değer doğrudan double olarak parse edilebiliyorsa (V4 JSON sayı formatı)
      double? direct = double.tryParse(value);
      if (direct != null) return direct;

      // V3 veya legacy formatlar için (örn: "2.450,00")
      // Nokta binlik, virgül ondalık ise
      if (value.contains('.') && value.contains(',')) {
        String cleaned = value.replaceAll('.', '').replaceAll(',', '.');
        return double.tryParse(cleaned);
      }

      // Sadece virgül varsa ondalıktır (örn: "32,54")
      if (value.contains(',')) {
        return double.tryParse(value.replaceAll(',', '.'));
      }

      return double.tryParse(value);
    } catch (e) {
      return null;
    }
  }
}
