import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomSpendingChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color primaryColor;
  final int selectedTimeframeIndex;

  const CustomSpendingChart({
    super.key,
    required this.data,
    required this.labels,
    this.primaryColor = const Color(0xFF6B5BF2),
    required this.selectedTimeframeIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    double maxVal = data.isEmpty ? 1.0 : data.reduce(math.max);
    if (maxVal == 0) maxVal = 1.0;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Grid lines
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) => Container(
                      height: 1,
                      width: double.infinity,
                      color: Colors.white.withValues(alpha: 0.05),
                    )),
                  ),
                  // Bars
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(data.length, (index) {
                          double heightFactor = data[index] / maxVal;
                          // Future or empty months stay at 0, no dip effect
                          bool hasData = data[index] > 0;
                          
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (hasData)
                                    Container(
                                      width: double.infinity,
                                      height: (constraints.maxHeight - 20) * heightFactor,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            primaryColor,
                                            primaryColor.withValues(alpha: 0.3),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryColor.withValues(alpha: 0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Container(
                                      width: double.infinity,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(labels.length, (index) {
            // Filter labels for density if needed
            bool showLabel = true;
            if (selectedTimeframeIndex == 1 && index % 5 != 0 && index != labels.length - 1) {
              showLabel = false;
            }
            if (selectedTimeframeIndex == 3 && index % 4 != 0) {
              showLabel = false;
            }

            return Expanded(
              child: Text(
                showLabel ? labels[index] : "",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// No longer used


class CustomComparisonBarChart extends StatelessWidget {
  final List<double> incomeData;
  final List<double> expenseData;
  final List<String> labels;
  final int selectedTimeframeIndex;

  const CustomComparisonBarChart({
    super.key,
    required this.incomeData,
    required this.expenseData,
    required this.labels,
    required this.selectedTimeframeIndex,
  });

  @override
  Widget build(BuildContext context) {
    double maxVal = math.max(
      incomeData.isNotEmpty ? incomeData.reduce(math.max) : 1.0,
      expenseData.isNotEmpty ? expenseData.reduce(math.max) : 1.0,
    );
    if (maxVal == 0) maxVal = 1.0;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(labels.length, (index) {
                  // Only show bars with data if daily/monthly
                  if ((selectedTimeframeIndex == 1 || selectedTimeframeIndex == 3) &&
                      incomeData[index] == 0 &&
                      expenseData[index] == 0 &&
                      labels[index].isEmpty) {
                    return const SizedBox();
                  }

                  final double availableHeight = constraints.maxHeight - 20;
                  double incomeHeight = (incomeData[index] / maxVal) * availableHeight;
                  double expenseHeight = (expenseData[index] / maxVal) * availableHeight;

                  return Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildBar(incomeHeight, const Color(0xFF4ADE80)),
                            const SizedBox(width: 4),
                            _buildBar(expenseHeight, const Color(0xFFF87171)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 12,
                          child: Text(
                            labels[index],
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 6,
      height: math.max(height, 2.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class CustomDonutChart extends StatelessWidget {
  final List<MapEntry<String, double>> data;
  final double total;
  final List<Color> colors;

  const CustomDonutChart({
    super.key,
    required this.data,
    required this.total,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 200),
      painter: _DonutPainter(
        data: data,
        total: total,
        colors: colors,
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final double total;
  final List<Color> colors;

  _DonutPainter({required this.data, required this.total, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    double startAngle = -math.pi / 2;

    if (total == 0) {
      final paint = Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12;
      canvas.drawCircle(center, radius - 6, paint);
      return;
    }

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 6),
        startAngle + 0.05, // small gap
        sweepAngle - 0.1,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
