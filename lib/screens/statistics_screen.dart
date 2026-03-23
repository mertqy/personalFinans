import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../providers/credit_card_provider.dart';
import '../core/utils.dart';
import '../widgets/spending_heatmap.dart';
import '../widgets/custom_statistics_charts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _selectedAccountIndex = 0;
  int _selectedTimeframeIndex = 2; // 0: Yıllık, 1: Aylık, 2: Haftalık, 3: Günlük

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionProvider);
    final accounts = ref.watch(accountProvider);
    final creditCards = ref.watch(creditCardProvider);

    final now = DateTime.now();

    // Filter transactions based on selection (Account filter)
    final filteredTransactions = transactions.where((tx) {
      if (tx.isPlanned) return false;
      bool accountMatch = true;
      if (_selectedAccountIndex > 0) {
        final selectedType = ['Tüm Hesaplar', 'Nakit', 'Kredi Kartı', 'Banka'][_selectedAccountIndex];
        final acc = accounts.where((a) => a.id == tx.accountId).firstOrNull;
        if (acc == null) {
          accountMatch = selectedType == 'Nakit' && tx.accountId.isEmpty;
        } else {
          accountMatch = acc.type == selectedType;
        }
      }
      return accountMatch;
    }).toList();

    // Data Aggregation based on timeframe
    final List<double> chartData;
    final List<String> chartLabels;
    final List<double> incomeChartData;
    final List<double> expenseChartData;
    double totalExpense = 0.0;

    switch (_selectedTimeframeIndex) {
      case 0: // Yıllık
        chartData = List.filled(12, 0.0);
        incomeChartData = List.filled(12, 0.0);
        expenseChartData = List.filled(12, 0.0);
        chartLabels = ['OCA', 'ŞUB', 'MAR', 'NİS', 'MAY', 'HAZ', 'TEM', 'AĞU', 'EYL', 'EKİ', 'KAS', 'ARA'];
        for (var tx in filteredTransactions.where((tx) => tx.date.year == now.year)) {
          final amount = AppUtils.getDisplayTRYAmount(tx, accounts, creditCards);
          int m = tx.date.month - 1;
          if (tx.type == 'income') {
            incomeChartData[m] += amount;
          } else if (tx.type == 'expense') {
            chartData[m] += amount;
            expenseChartData[m] += amount;
            totalExpense += amount;
          }
        }
        break;
      case 1: // Aylık
        int lastDay = DateTime(now.year, now.month + 1, 0).day;
        chartData = List.filled(lastDay, 0.0);
        incomeChartData = List.filled(lastDay, 0.0);
        expenseChartData = List.filled(lastDay, 0.0);
        chartLabels = List.generate(lastDay, (i) => (i + 1) % 5 == 0 ? (i + 1).toString() : "");
        for (var tx in filteredTransactions.where((tx) => tx.date.year == now.year && tx.date.month == now.month)) {
          final amount = AppUtils.getDisplayTRYAmount(tx, accounts, creditCards);
          int d = tx.date.day - 1;
          if (tx.type == 'income') {
            incomeChartData[d] += amount;
          } else if (tx.type == 'expense') {
            chartData[d] += amount;
            expenseChartData[d] += amount;
            totalExpense += amount;
          }
        }
        break;
      case 3: // Günlük
        chartData = List.filled(24, 0.0);
        incomeChartData = List.filled(24, 0.0);
        expenseChartData = List.filled(24, 0.0);
        chartLabels = List.generate(24, (i) => i % 4 == 0 ? "${i.toString().padLeft(2, '0')}:00" : "");
        for (var tx in filteredTransactions.where((tx) => tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day)) {
          final amount = AppUtils.getDisplayTRYAmount(tx, accounts, creditCards);
          int h = tx.date.hour;
          if (tx.type == 'income') {
            incomeChartData[h] += amount;
          } else if (tx.type == 'expense') {
            chartData[h] += amount;
            expenseChartData[h] += amount;
            totalExpense += amount;
          }
        }
        break;
      case 2: // Haftalık
      default:
        chartData = List.filled(7, 0.0);
        incomeChartData = List.filled(7, 0.0);
        expenseChartData = List.filled(7, 0.0);
        chartLabels = ['PZT', 'SAL', 'ÇAR', 'PER', 'CUM', 'CMT', 'PAZ'];
        DateTime startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        for (var tx in filteredTransactions) {
          final txDateOnly = DateTime(tx.date.year, tx.date.month, tx.date.day);
          final diff = txDateOnly.difference(startOfWeek).inDays;
          if (diff >= 0 && diff < 7) {
            final amount = AppUtils.getDisplayTRYAmount(tx, accounts, creditCards);
            if (tx.type == 'income') {
              incomeChartData[diff] += amount;
            } else if (tx.type == 'expense') {
              chartData[diff] += amount;
              expenseChartData[diff] += amount;
              totalExpense += amount;
            }
          }
        }
        break;
    }

    // Category Breakdown Calculation (Based on same filters)
    final Map<String, double> categoryMap = {};
    for (var tx in filteredTransactions.where((t) => t.type == 'expense')) {
      // Filter for timeframe as well for category breakdown consistency
      bool inTimeframe = false;
      switch (_selectedTimeframeIndex) {
        case 0: inTimeframe = tx.date.year == now.year; break;
        case 1: inTimeframe = tx.date.year == now.year && tx.date.month == now.month; break;
        case 3: inTimeframe = tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day; break;
        case 2: 
          DateTime startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
          final diff = DateTime(tx.date.year, tx.date.month, tx.date.day).difference(startOfWeek).inDays;
          inTimeframe = diff >= 0 && diff < 7;
          break;
      }
      
      if (inTimeframe) {
        final amount = AppUtils.getDisplayTRYAmount(tx, accounts, creditCards);
        categoryMap[tx.category] = (categoryMap[tx.category] ?? 0) + amount;
      }
    }
    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));


    // Constants for colors matches image
    const Color bgColor = Color(0xFF0F121C); // Very dark bg
    const Color cardColor = Color(0xFF1B2033); // Card bg
    const Color primaryPurple = Color(0xFF6B5BF2);
    const Color successGreen = Color(0xFF00D287);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Detaylı İstatistikler',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Horizontal Account Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterPill('Tüm Hesaplar', 0, _selectedAccountIndex, primaryPurple),
                    const SizedBox(width: 8),
                    _buildFilterPill('Nakit', 1, _selectedAccountIndex, primaryPurple),
                    const SizedBox(width: 8),
                    _buildFilterPill('Kredi Kartı', 2, _selectedAccountIndex, primaryPurple),
                    const SizedBox(width: 8),
                    _buildFilterPill('Banka', 3, _selectedAccountIndex, primaryPurple),
                  ],
                ),
              ).animate().fade(duration: 400.ms).slideX(begin: 0.1),
              const SizedBox(height: 16),
              
              // Timeframe Filters
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildTimeframeTab('Yıllık', 0)),
                    Expanded(child: _buildTimeframeTab('Aylık', 1)),
                    Expanded(child: _buildTimeframeTab('Haftalık', 2)),
                    Expanded(child: _buildTimeframeTab('Günlük', 3)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Net Değişim Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOPLAM HARCAMA',
                              style: TextStyle(

                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppUtils.formatCurrency(totalExpense, currency: 'TRY'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: successGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.trending_down, color: successGreen, size: 14),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '%15.2',
                                    style: TextStyle(
                                        color: successGreen,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Geçen haftaya göre',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 10),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 48),
                    // Custom Chart (Bar Chart beneath Line Chart)
                    SizedBox(
                      height: 180,
                      child: CustomSpendingChart(
                        data: chartData,
                        labels: chartLabels,
                        primaryColor: primaryPurple,
                        selectedTimeframeIndex: _selectedTimeframeIndex,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),


              const SizedBox(height: 16),


              // Harcama Yoğunluğu
              SpendingHeatmap(
                filteredTransactions: filteredTransactions,
                accounts: accounts,
                creditCards: creditCards,
              ),
              const SizedBox(height: 32),

              // Gelir ve Gider Kıyaslaması
              const Text(
                'Gelir ve Gider Kıyaslaması',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                height: 250,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: CustomComparisonBarChart(
                        incomeData: incomeChartData,
                        expenseData: expenseChartData,
                        labels: chartLabels,
                        selectedTimeframeIndex: _selectedTimeframeIndex,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendPair(const Color(0xFF4ADE80), 'Gelir'),
                        const SizedBox(width: 24),
                        _buildLegendPair(const Color(0xFFF87171), 'Gider'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Kategori Dağılımı (New Custom Chart)
              const Text(
                'Kategori Dağılımı',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'TOPLAM',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                AppUtils.formatCurrency(totalExpense, currency: 'TRY').split(',')[0],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          CustomDonutChart(
                            data: sortedCategories.take(5).toList(),
                            total: totalExpense,
                            colors: const [
                              Color(0xFF6B5BF2),
                              Color(0xFF00D287),
                              Color(0xFFFFB300),
                              Color(0xFFFF4848),
                              Color(0xFF00B2FF),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Column(
                      children: sortedCategories.take(5).map((cat) {
                         final index = sortedCategories.indexOf(cat);
                         final colors = [
                                    const Color(0xFF6B5BF2),
                                    const Color(0xFF00D287),
                                    const Color(0xFFFFB300),
                                    const Color(0xFFFF4848),
                                    const Color(0xFF00B2FF),
                                  ];
                         final percentage = (totalExpense > 0) ? (cat.value / totalExpense * 100) : 0.0;
                         return Padding(
                           padding: const EdgeInsets.only(bottom: 12.0),
                           child: Row(
                             children: [
                               Container(
                                 width: 12,
                                 height: 12,
                                 decoration: BoxDecoration(
                                   color: colors[index % colors.length],
                                   shape: BoxShape.circle,
                                 ),
                               ),
                               const SizedBox(width: 8),
                               Expanded(
                                 child: Text(
                                   AppUtils.getCategoryName(cat.key),
                                   style: const TextStyle(color: Colors.white70, fontSize: 14),
                                 ),
                               ),
                               Text(
                                 "${percentage.toStringAsFixed(1)}%",
                                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                               ),
                               const SizedBox(width: 12),
                               Text(
                                 AppUtils.formatCurrency(cat.value),
                                 style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                               ),
                             ],
                           ),
                         );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String title, int index, int selectedIndex, Color primaryColor) {
    bool isSelected = index == selectedIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedAccountIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isSelected ? null : Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeframeTab(String title, int index) {
    bool isSelected = index == _selectedTimeframeIndex;
    return GestureDetector(
      onTap: () => setState(() => _selectedTimeframeIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF282D45) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendPair(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
        ),
      ],
    );
  }


}
