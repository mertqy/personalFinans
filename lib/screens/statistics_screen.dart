import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistikler'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Harcama Dağılımı', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              SizedBox(
                height: 300,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 0,
                    centerSpaceRadius: 60,
                    sections: showingSections(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ..._buildIndicators(),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(4, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 70.0 : 60.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      switch (i) {
        case 0:
          return PieChartSectionData(
            color: AppConstants.chartColors['PRIMARY']!,
            value: 40,
            title: '40%',
            radius: radius,
            titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white, shadows: shadows),
          );
        case 1:
          return PieChartSectionData(
            color: AppConstants.chartColors['WARNING']!,
            value: 30,
            title: '30%',
            radius: radius,
            titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white, shadows: shadows),
          );
        case 2:
          return PieChartSectionData(
            color: AppConstants.chartColors['INFO']!,
            value: 15,
            title: '15%',
            radius: radius,
            titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white, shadows: shadows),
          );
        case 3:
          return PieChartSectionData(
            color: AppConstants.chartColors['PURPLE']!,
            value: 15,
            title: '15%',
            radius: radius,
            titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white, shadows: shadows),
          );
        default:
          throw Error();
      }
    });
  }

  List<Widget> _buildIndicators() {
    return [
      _Indicator(color: AppConstants.chartColors['PRIMARY']!, text: 'Yiyecek & İçecek'),
      const SizedBox(height: 8),
      _Indicator(color: AppConstants.chartColors['WARNING']!, text: 'Market'),
      const SizedBox(height: 8),
      _Indicator(color: AppConstants.chartColors['INFO']!, text: 'Ulaşım'),
      const SizedBox(height: 8),
      _Indicator(color: AppConstants.chartColors['PURPLE']!, text: 'Fatura'),
    ];
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
