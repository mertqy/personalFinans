import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../providers/credit_card_provider.dart';
import '../core/utils.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _ChartData {
  _ChartData(this.x, this.y, [this.color]);
  final dynamic x;
  final double y;
  final Color? color;
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  bool isExpenseView = true;
  late TooltipBehavior _trendTooltip;
  late TooltipBehavior _comparisonTooltip;
  late TooltipBehavior _pieTooltip;

  @override
  void initState() {
    final symbol = AppUtils.getCurrencySymbol('TRY');
    _trendTooltip = TooltipBehavior(enable: true, format: 'point.x : $symbol point.y');
    _comparisonTooltip = TooltipBehavior(enable: true, shared: true, format: '$symbol point.y');
    _pieTooltip = TooltipBehavior(enable: true, format: 'point.x : $symbol point.y');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionProvider);
    final accounts = ref.watch(accountProvider);
    final creditCards = ref.watch(creditCardProvider);
    
    final filteredTransactions = transactions
        .where((t) => t.type == (isExpenseView ? 'expense' : 'income') && !t.isPlanned)
        .toList();

    String getTxCurrency(dynamic tx) {
      if (tx.accountId.isNotEmpty) {
        final acc = accounts.where((a) => a.id == tx.accountId).firstOrNull;
        if (acc != null) return acc.currency;
      } else if (tx.creditCardId != null) {
        final card = creditCards.where((c) => c.id == tx.creditCardId).firstOrNull;
        if (card != null) {
          final acc = accounts.where((a) => a.id == card.accountId).firstOrNull;
          if (acc != null) return acc.currency;
        }
      }
      return 'TRY';
    }
    
    // Group by category
    final Map<String, double> categoryMap = {};
    double totalAmount = 0;
    for (var tx in filteredTransactions) {
      final normalizedCategory = AppUtils.getCategoryById(tx.category)?['id'] ?? tx.category;
      final convertedAmount = AppUtils.convertToBaseCurrency(tx.amount, getTxCurrency(tx), 'TRY');
      categoryMap[normalizedCategory] = (categoryMap[normalizedCategory] ?? 0) + convertedAmount;
      totalAmount += convertedAmount;
    }

    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Colors for pie chart
    final chartColors = [
      AppConstants.chartColors['PRIMARY']!,
      AppConstants.chartColors['WARNING']!,
      AppConstants.chartColors['INFO']!,
      AppConstants.chartColors['PURPLE']!,
      AppConstants.chartColors['SUCCESS']!,
      AppConstants.chartColors['PINK']!,
      AppConstants.chartColors['DANGER']!,
    ];

    // Pie chart için verileri düzenle (ilk 6 + Diğer)
    final List<_ChartData> pieData = [];
    if (sortedCategories.length <= 7) {
      for (int i = 0; i < sortedCategories.length; i++) {
        final e = sortedCategories[i];
        pieData.add(_ChartData(AppUtils.getCategoryName(e.key), e.value, chartColors[i % chartColors.length]));
      }
    } else {
      for (int i = 0; i < 6; i++) {
        final e = sortedCategories[i];
        pieData.add(_ChartData(AppUtils.getCategoryName(e.key), e.value, chartColors[i]));
      }
      double otherTotal = 0;
      for (int i = 6; i < sortedCategories.length; i++) {
        otherTotal += sortedCategories[i].value;
      }
      pieData.add(_ChartData('Diğer', otherTotal, Colors.grey));
    }

    // Data for Trend Chart (Last 7 days)
    final now = DateTime.now();
    final last7Days = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return DateTime(date.year, date.month, date.day);
    });

    final List<_ChartData> trendData = last7Days.map((date) {
      final dayTotal = filteredTransactions
          .where((t) => t.date.year == date.year && t.date.month == date.month && t.date.day == date.day)
          .fold(0.0, (sum, t) => sum + AppUtils.convertToBaseCurrency(t.amount, getTxCurrency(t), 'TRY'));
      return _ChartData(DateFormat('E', 'tr_TR').format(date), dayTotal);
    }).toList();

    // Data for Monthly Comparison
    final currentMonth = now.month;
    final currentYear = now.year;
    final prevMonthDate = DateTime(now.year, now.month - 1);
    final prevMonth = prevMonthDate.month;
    final prevYear = prevMonthDate.year;

    final currentMonthDays = DateTime(currentYear, currentMonth + 1, 0).day;
    final List<_ChartData> currentMonthData = List.generate(currentMonthDays, (index) {
      final day = index + 1;
      final dayTotal = filteredTransactions
          .where((t) => t.date.year == currentYear && t.date.month == currentMonth && t.date.day == day)
          .fold(0.0, (sum, t) => sum + AppUtils.convertToBaseCurrency(t.amount, getTxCurrency(t), 'TRY'));
      return _ChartData(day, dayTotal);
    });

    final prevMonthDays = DateTime(prevYear, prevMonth + 1, 0).day;
    final List<_ChartData> prevMonthData = List.generate(prevMonthDays, (index) {
      final day = index + 1;
      final dayTotal = filteredTransactions
          .where((t) => t.date.year == prevYear && t.date.month == prevMonth && t.date.day == day)
          .fold(0.0, (sum, t) => sum + AppUtils.convertToBaseCurrency(t.amount, getTxCurrency(t), 'TRY'));
      return _ChartData(day, dayTotal);
    });

    final themeColor = isExpenseView 
        ? Theme.of(context).colorScheme.primary 
        : Colors.green;

    return Scaffold(
      appBar: AppBar(title: const Text('İstatistikler')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildToggleControl(),
              const SizedBox(height: 24),

              // Pie Chart
              _buildSectionTitle(isExpenseView ? 'Kategori Bazlı Harcama' : 'Kategori Bazlı Gelir'),
              const SizedBox(height: 16),
              if (totalAmount > 0) ...[
                _buildPieChart(pieData, totalAmount, themeColor),
                const SizedBox(height: 16),
                _buildCategoryList(pieData, totalAmount),
              ] else 
                _buildEmptyState(isExpenseView ? 'Harcama verisi bulunamadı' : 'Gelir verisi bulunamadı'),

              const SizedBox(height: 40),

              // Trend Chart
              _buildSectionTitle('Son 7 Günlük Trend'),
              const SizedBox(height: 16),
              if (totalAmount > 0)
                _buildTrendChart(trendData, themeColor)
              else 
                _buildEmptyState('Trend verisi yok'),
              
              const SizedBox(height: 40),

              // Comparison Chart
              _buildSectionTitle('Aylık Karşılaştırma'),
              const SizedBox(height: 16),
              if (totalAmount > 0)
                _buildComparisonChart(currentMonthData, prevMonthData, themeColor)
              else 
                _buildEmptyState('Karşılaştırma verisi yok'),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleControl() {
    return Center(
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: true, label: Text('Giderler'), icon: Icon(Icons.outbound)),
          ButtonSegment(value: false, label: Text('Gelirler'), icon: Icon(Icons.move_to_inbox)),
        ],
        selected: {isExpenseView},
        onSelectionChanged: (newSelection) => setState(() => isExpenseView = newSelection.first),
      ),
    );
  }

  Widget _buildPieChart(List<_ChartData> data, double total, Color centerColor) {
    return SizedBox(
      height: 250,
      child: SfCircularChart(
        tooltipBehavior: _pieTooltip,
        annotations: <CircularChartAnnotation>[
          CircularChartAnnotation(
            widget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Toplam', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text(
                  AppUtils.formatCurrency(total),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: centerColor,
                  ),
                ),
              ],
            ),
          ),
        ],
        series: <CircularSeries<_ChartData, String>>[
          DoughnutSeries<_ChartData, String>(
            dataSource: data,
            xValueMapper: (_ChartData d, _) => d.x as String,
            yValueMapper: (_ChartData d, _) => d.y,
            pointColorMapper: (_ChartData d, _) => d.color,
            innerRadius: '70%',
            radius: '100%',
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.outside,
              textStyle: TextStyle(fontSize: 10),
            ),
            enableTooltip: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<_ChartData> data, Color color) {
    return SizedBox(
      height: 220,
      child: SfCartesianChart(
        primaryXAxis: const CategoryAxis(
          majorGridLines: MajorGridLines(width: 0),
          labelStyle: TextStyle(fontSize: 10),
        ),
        primaryYAxis: const NumericAxis(
          minimum: 0,
          majorGridLines: MajorGridLines(dashArray: [5, 5]),
          labelStyle: TextStyle(fontSize: 10),
        ),
        tooltipBehavior: _trendTooltip,
        series: <CartesianSeries<_ChartData, String>>[
          SplineAreaSeries<_ChartData, String>(
            dataSource: data,
            xValueMapper: (_ChartData d, _) => d.x as String,
            yValueMapper: (_ChartData d, _) => d.y,
            color: color.withOpacity(0.1),
            borderColor: color,
            borderWidth: 3,
            markerSettings: MarkerSettings(
              isVisible: true,
              height: 4,
              width: 4,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonChart(List<_ChartData> current, List<_ChartData> prev, Color color) {
    return SizedBox(
      height: 220,
      child: SfCartesianChart(
        legend: const Legend(isVisible: true, position: LegendPosition.top),
        primaryXAxis: const NumericAxis(
          majorGridLines: MajorGridLines(width: 0),
          interval: 5,
          labelStyle: TextStyle(fontSize: 10),
        ),
        primaryYAxis: const NumericAxis(
          minimum: 0,
          majorGridLines: MajorGridLines(dashArray: [5, 5]),
          labelStyle: TextStyle(fontSize: 10),
        ),
        tooltipBehavior: _comparisonTooltip,
        series: <CartesianSeries<_ChartData, num>>[
          SplineSeries<_ChartData, num>(
            name: 'Bu Ay',
            dataSource: current,
            xValueMapper: (_ChartData d, _) => d.x as num,
            yValueMapper: (_ChartData d, _) => d.y,
            color: color,
            width: 3,
          ),
          SplineSeries<_ChartData, num>(
            name: 'Geçen Ay',
            dataSource: prev,
            xValueMapper: (_ChartData d, _) => d.x as num,
            yValueMapper: (_ChartData d, _) => d.y,
            color: Colors.grey.withOpacity(0.4),
            width: 2,
            dashArray: const [5, 5],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List<_ChartData> pieData, double total) {
    return Column(
      children: List.generate(pieData.length, (i) {
        final d = pieData[i];
        final percentage = (d.y / total) * 100;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(shape: BoxShape.circle, color: d.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(d.x as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              Text('%${NumberFormat('##0.0', 'tr_TR').format(percentage)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 15),
              Text(AppUtils.formatCurrency(d.y), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.3));
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.pie_chart_outline, size: 40, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

