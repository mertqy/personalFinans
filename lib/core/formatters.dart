import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat.decimalPattern('tr_TR');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Sadece sayıları al (nokta ve virgül hariç, çünkü ondalıklı değil tam sayı binlik ayracı istiyoruz genelde tutarlarda)
    // Eğer ondalık kısımlar da isteniyorsa farklı bir mantık gerekir. 
    // Kullanıcı talebi binlik ayracı (nokta) olduğu için TR formatında binlik nokta, ondalık virgüldür.
    // Şimdilik tam sayı gibi binlik ayracı ekleyelim.
    
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '', selection: const TextSelection.collapsed(offset: 0));
    }

    double value = double.parse(cleanText);
    String formattedText = _formatter.format(value);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  /// Formatlı metni (örn: "1.250") saf sayıya (1250) çevirir.
  static double parse(String text) {
    if (text.isEmpty) return 0.0;
    return double.tryParse(text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
  }

  /// Bir sayıyı binlik ayracı (nokta) ile formatlar.
  static String format(double value) {
    return _formatter.format(value.floor()); // Tam sayı için yapıyoruz
  }
}
