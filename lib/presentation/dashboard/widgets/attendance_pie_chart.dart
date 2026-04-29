import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/dashboard_stats_model.dart';
import 'package:sri_hr/presentation/dashboard/widgets/legend_item.dart';
import 'package:sri_hr/presentation/dashboard/widgets/section_header.dart';
import 'package:sri_hr/widgets/sri_card.dart';
import 'package:fl_chart/fl_chart.dart';

class AttendancePieChart extends StatelessWidget {
  final DashboardStats? stats;
  const AttendancePieChart({super.key, this.stats});

  @override
  Widget build(BuildContext context) {
    final present = stats?.presentCount.toDouble() ?? 0;
    final absent = stats?.absentCount.toDouble() ?? 0;
    final onLeave = stats?.leaveCount.toDouble() ?? 0;
    final total = present + absent + onLeave;

    return SriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Today\'s Attendance'),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: total == 0
                ? const Center(
                    child: Text(
                      'No data',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 50,
                            sections: [
                              PieChartSectionData(
                                value: present,
                                color: AppColors.success,
                                title: '${present.toInt()}',
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              PieChartSectionData(
                                value: absent,
                                color: AppColors.error,
                                title: '${absent.toInt()}',
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              PieChartSectionData(
                                value: onLeave,
                                color: AppColors.warning,
                                title: '${onLeave.toInt()}',
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LegendItem(
                            color: AppColors.success,
                            label: 'Present',
                            count: present.toInt(),
                          ),
                          const SizedBox(height: 12),
                          LegendItem(
                            color: AppColors.error,
                            label: 'Absent',
                            count: absent.toInt(),
                          ),
                          const SizedBox(height: 12),
                          LegendItem(
                            color: AppColors.warning,
                            label: 'On Leave',
                            count: onLeave.toInt(),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
