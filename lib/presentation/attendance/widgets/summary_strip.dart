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

      final empIds = rows.map((r) => r["employeeId"] as String).toSet();
      final present = empIds.length;
      final totalMins =
          rows.fold<int>(0, (s, r) => s + (r['totalMins'] as int));
      final avgHrs =
          rows.isEmpty ? 0.0 : totalMins / 60.0 / rows.length;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: AppColors.surface,
        child: Row(
          children: [
            Chips(
              value: '${rows.length}',
              label: 'Records',
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Chips(
              value: '$present',
              label: 'Employees',
              color: AppColors.info,
            ),
            const SizedBox(width: 10),
            Chips(
              value: '${avgHrs.toStringAsFixed(1)}h',
              label: 'Avg/Day',
              color: AppColors.success,
            ),
          ],
        ),
      );
    });
  }
}