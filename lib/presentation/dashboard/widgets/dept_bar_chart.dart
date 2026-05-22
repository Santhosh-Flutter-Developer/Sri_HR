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

    // ✅ Remove Unknown departments
    final filteredData = data.where((e) {
      final name = e['name'].toString().trim().toLowerCase();
      return name.isNotEmpty && name != 'unknown';
    }).toList();

    // ✅ Highest count
    final maxCount = filteredData.isEmpty
        ? 1
        : filteredData
                .map((e) => (e['count'] as int))
                .reduce((a, b) => a > b ? a : b) +
            1;

    return SriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Department Headcount'),
          const SizedBox(height: 20),

          SizedBox(
            height: 220,

            // ✅ No Data UI
            child: filteredData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 42,
                          color: AppColors.textMuted.withOpacity(0.5),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'No department data available',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )

                // ✅ Chart
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,

                      minY: 0,
                      maxY: maxCount.toDouble(),

                      // ✅ Tooltip
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipPadding: const EdgeInsets.all(8),
                          tooltipMargin: 8,
                          tooltipBorderRadius: BorderRadius.circular(8.0),
                          getTooltipColor: (_) => Colors.black87,

                          getTooltipItem:
                              (group, groupIndex, rod, rodIndex) {
                            final item =
                                filteredData[group.x.toInt()];

                            final name =
                                item['name'].toString();

                            return BarTooltipItem(
                              '$name\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      'Count: ${item['count']}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      // ✅ Titles
                      titlesData: FlTitlesData(
                        // LEFT
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,

                            getTitlesWidget:
                                (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color:
                                      AppColors.textMuted,
                                ),
                              );
                            },
                          ),
                        ),

                        // BOTTOM
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,

                            getTitlesWidget:
                                (value, meta) {
                              final idx =
                                  value.toInt();

                              if (idx >= 0 &&
                                  idx <
                                      filteredData
                                          .length) {
                                final name =
                                    filteredData[idx]
                                            ['name']
                                        .toString();

                                return Padding(
                                  padding:
                                      const EdgeInsets.only(
                                        top: 6,
                                      ),
                                  child: Text(
                                    name.length > 8
                                        ? '${name.substring(0, 7)}..'
                                        : name,
                                    style:
                                        const TextStyle(
                                          fontSize: 9,
                                          color:
                                              AppColors
                                                  .textMuted,
                                        ),
                                    textAlign:
                                        TextAlign.center,
                                  ),
                                );
                              }

                              return const SizedBox.shrink();
                            },
                          ),
                        ),

                        rightTitles: AxisTitles(
                          sideTitles:
                              SideTitles(
                                showTitles: false,
                              ),
                        ),

                        topTitles: AxisTitles(
                          sideTitles:
                              SideTitles(
                                showTitles: false,
                              ),
                        ),
                      ),

                      // ✅ Grid
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,

                        getDrawingHorizontalLine:
                            (_) => FlLine(
                              color:
                                  AppColors.border,
                              strokeWidth: 1,
                            ),
                      ),

                      borderData: FlBorderData(
                        show: false,
                      ),

                      // ✅ Bars
                      barGroups: filteredData
                          .asMap()
                          .entries
                          .map(
                            (e) => BarChartGroupData(
                              x: e.key,

                              barRods: [
                                BarChartRodData(
                                  toY:
                                      (e.value['count']
                                              as int)
                                          .toDouble(),

                                  color:
                                      AppColors.primary,

                                  width: 28,

                                  borderRadius:
                                      const BorderRadius.vertical(
                                        top:
                                            Radius.circular(
                                              6,
                                            ),
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