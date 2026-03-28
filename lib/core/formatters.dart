import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat.decimalPattern('tr_TR');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Sadece sayıları al (nokta ve virgül hariç, çünkü ondalıklı değil tam sayı binlik ayracı istiyoruz genelde tutarlarda)
    // Eğer ondalık kısımlar da isteniyorsa farklı bir mantık gerekir.
    // Kullanıcı talebi binlik ayracı (nokta) olduğu için TR formatında binlik nokta, ondalık virgüldür.
    // Şimdilik tam sayı gibi binlik ayracı ekleyelim.

    // Ondalık ayracı desteği ekleyelim (TR formatında virgül)
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9,]'), '');

    // Birden fazla virgül varsa sadece ilkini tut
    if (cleanText.contains(',')) {
      final parts = cleanText.split(',');
      cleanText = '${parts[0]},${parts.sublist(1).join('')}';
    }

    if (cleanText.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Virgüllü kısmı korumak için double.parse yerine metin manipülasyonu kullanalım
    String formattedText;
    final commaIndex = cleanText.indexOf(',');

    if (commaIndex != -1) {
      final beforeComma = cleanText.substring(0, commaIndex);
      final afterComma = cleanText.substring(commaIndex + 1);

      final double doubleValue = double.tryParse(beforeComma) ?? 0;
      formattedText = _formatter.format(doubleValue);
      formattedText = '$formattedText,$afterComma';
    } else {
      final double doubleValue = double.tryParse(cleanText) ?? 0;
      formattedText = _formatter.format(doubleValue);
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  /// Formatlı metni (örn: "1.250") saf sayıya (1250) çevirir.
  static double parse(String text) {
    if (text.isEmpty) return 0.0;
    return double.tryParse(text.replaceAll('.', '').replaceAll(',', '.')) ??
        0.0;
  }

  /// Bir sayıyı binlik ayracı (nokta) ve ondalık (virgül) ile formatlar.
  static String format(double value) {
    // floor() kullanmıyoruz ki ondalık kısımlar kaybolmasın
    return _formatter.format(value);
  }
}
