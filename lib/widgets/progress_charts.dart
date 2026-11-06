import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Simple weekly bar chart for the tracker/reports.
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 180,
  });

  /// One value per day (7 entries).
  final List<int> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color barColor =
        isDark ? AppColors.hcDarkPrimary : AppColors.primary;
    final Color gridColor =
        isDark ? AppColors.darkOutline : AppColors.outline;

    if (values.isEmpty || values.every((int v) => v == 0)) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('No data for this period yet.',
              style: Theme.of(context).textTheme.bodySmall),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (values.fold<int>(0, (int a, int b) => a > b ? a : b) + 2)
              .toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (double value) => FlLine(
              color: gridColor.withValues(alpha: 0.4),
              strokeWidth: 0.6,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (double v, TitleMeta meta) {
                  final int i = v.toInt();
                  if (i < 0 || i >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(labels[i],
                        style: Theme.of(context).textTheme.labelSmall),
                  );
                },
              ),
            ),
          ),
          barGroups: List<BarChartGroupData>.generate(values.length,
              (int i) {
            return BarChartGroupData(
              x: i,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: values[i].toDouble(),
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                  color: barColor,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Pie chart of communication-method usage with a legend.
class MethodPieChart extends StatelessWidget {
  const MethodPieChart({
    super.key,
    required this.sections,
    this.height = 180,
  });

  /// (label, count, colorName) triples.
  final List<(String, int, String)> sections;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final List<(String, int, Color)> data = <(String, int, Color)>[
      for (final (String label, int count, String colorName) in sections)
        if (count > 0)
          (
            label,
            count,
            isDark
                ? AppColors.fromName(colorName).withValues(alpha: 0.8)
                : AppColors.fromName(colorName),
          ),
    ];

    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('No data for this period yet.',
              style: Theme.of(context).textTheme.bodySmall),
        ),
      );
    }

    final int total = data.fold(
        0, (int sum, (String, int, Color) e) => sum + e.$2);

    return SizedBox(
      height: height,
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 34,
                sections: <PieChartSectionData>[
                  for (final (_, int count, Color color) in data)
                    PieChartSectionData(
                      value: count.toDouble(),
                      title: '${(count * 100 / total).round()}%',
                      titleStyle: Theme.of(context).textTheme.labelSmall,
                      color: color,
                      radius: 42,
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final (String label, int count, Color color) in data)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('$label ($count)',
                              overflow: TextOverflow.ellipsis,
                              style:
                                  Theme.of(context).textTheme.labelSmall),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
