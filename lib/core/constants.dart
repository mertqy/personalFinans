import 'package:flutter/material.dart';

class AppConstants {
  static const List<Map<String, dynamic>> defaultCategories = [
    // Gelir Kategorileri
    {'id': 'income-salary', 'name': 'Maaş', 'icon': '💼', 'type': 'income'},
    {'id': 'income-freelance', 'name': 'Serbest Çalışma', 'icon': '💻', 'type': 'income'},
    {'id': 'income-investment', 'name': 'Yatırım', 'icon': '📈', 'type': 'income'},
    {'id': 'income-other', 'name': 'Diğer Gelir', 'icon': '💰', 'type': 'income'},

    // Gider Kategorileri
    {'id': 'expense-food', 'name': 'Yiyecek', 'icon': '🍽️', 'type': 'expense'},
    {'id': 'expense-transport', 'name': 'Ulaşım', 'icon': '🚗', 'type': 'expense'},
    {'id': 'expense-pet', 'name': 'Hayvan Bakımı', 'icon': '🐶', 'type': 'expense'},
    {'id': 'expense-housing', 'name': 'Barınma', 'icon': '🏠', 'type': 'expense'},
    {'id': 'expense-healthcare', 'name': 'Sağlık', 'icon': '🏥', 'type': 'expense'},
    {'id': 'expense-entertainment', 'name': 'Eğlence', 'icon': '🎬', 'type': 'expense'},
    {'id': 'expense-shopping', 'name': 'Alışveriş', 'icon': '🛍️', 'type': 'expense'},
    {'id': 'expense-utilities', 'name': 'Faturalar', 'icon': '⚡', 'type': 'expense'},
    {'id': 'expense-education', 'name': 'Eğitim', 'icon': '📚', 'type': 'expense'},
    {'id': 'expense-other', 'name': 'Diğer Giderler', 'icon': '💸', 'type': 'expense'},
  ];

  static const Map<String, Map<String, String>> currencies = {
    'TRY': {'symbol': '₺', 'name': 'Türk Lirası'},
    'USD': {'symbol': '\$', 'name': 'US Dollar'},
    'EUR': {'symbol': '€', 'name': 'Euro'},
    'GBP': {'symbol': '£', 'name': 'British Pound'},
    'GOLD': {'symbol': 'Au', 'name': 'Altın (Gram)'},
  };

  static const String defaultCurrency = 'TRY';

  static const Map<String, Color> chartColors = {
    'PRIMARY': Color(0xFF3B82F6),
    'SUCCESS': Color(0xFF10B981),
    'WARNING': Color(0xFFF59E0B),
    'DANGER': Color(0xFFEF4444),
    'INFO': Color(0xFF06B6D4),
    'PURPLE': Color(0xFF8B5CF6),
    'PINK': Color(0xFFEC4899),
    'GRAY': Color(0xFF6B7280),
  };

  static const List<Map<String, String>> recurringFrequencies = [
    {'value': 'daily', 'label': 'Günlük'},
    {'value': 'weekly', 'label': 'Haftalık'},
    {'value': 'monthly', 'label': 'Aylık'},
    {'value': 'yearly', 'label': 'Yıllık'},
  ];

  static const List<Map<String, String>> budgetPeriods = [
    {'value': 'monthly', 'label': 'Aylık'},
    {'value': 'yearly', 'label': 'Yıllık'},
  ];
}
