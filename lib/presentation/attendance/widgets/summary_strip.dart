import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/attendance/widgets/chips.dart';

class SummaryStrip extends StatelessWidget {
  final AttendanceController controller;

  const SummaryStrip({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rows = controller.groupedByEmployeeDate;
      final present = controller.presentCount;
      final absent = controller.absentCount;
      final singleDay = controller.isSingleDay;
      final totalMins = rows.fold<int>(
        0,
        (s, r) => s + (r['totalMins'] as int),
      );
      final avgHrs = rows.isEmpty ? 0.0 : totalMins / 60.0 / rows.length;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: AppColors.surface,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Chips(
                  value: '${rows.length}',
                  label: 'Records',
                  color: AppColors.primary,
                ),
                SizedBox(width: 6.0),
                if (singleDay) ...[
                  Chips(
                    value: '$present',
                    label: 'Present',
                    color: AppColors.success,
                    selected: controller.statusFilter.value == 'present',
                    onTap: () => controller.toggleStatusFilter('present'),
                  ),
                  SizedBox(width: 6.0),

                  Chips(
                    value: '$absent',
                    label: 'Absent',
                    color: AppColors.error,
                    selected: controller.statusFilter.value == 'absent',
                    onTap: () => controller.toggleStatusFilter('absent'),
                  ),
                  SizedBox(width: 6.0),
                ],
                Chips(
                  value: '${avgHrs.toStringAsFixed(1)}h',
                  label: 'Avg/Day',
                  color: AppColors.info,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}