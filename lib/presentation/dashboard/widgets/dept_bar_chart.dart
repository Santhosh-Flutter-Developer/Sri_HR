import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/dashboard_stats_model.dart';
import 'package:sri_hr/presentation/dashboard/widgets/section_header.dart';
import 'package:sri_hr/widgets/sri_card.dart';

class DeptBarChart extends StatelessWidget {
  final DashboardStats? stats;
  const DeptBarChart({super.key, this.stats});

  @override
  Widget build(BuildContext context) {
    final data = stats?.departmentWiseCount ?? [];
    return SriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Department Headcount'),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: data.isEmpty
                ? const Center(
                    child: Text(
                      'No departments',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (v, m) => Text(
                              '${v.toInt()}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (v, m) {
                              final idx = v.toInt();
                              if (idx >= 0 && idx < data.length) {
                                final name = data[idx]['name'] as String;
                                return Text(
                                  name.length > 6
                                      ? '${name.substring(0, 5)}..'
                                      : name,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textMuted,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: AppColors.border, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: data
                          .asMap()
                          .entries
                          .map(
                            (e) => BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: (e.value['count'] as int).toDouble(),
                                  color: AppColors.primary,
                                  width: 28,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
