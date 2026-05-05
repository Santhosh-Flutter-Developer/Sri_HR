import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/attendance_log_model.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/attendance/widgets/summary_chip.dart';
import 'package:sri_hr/widgets/sri_button.dart';

class FiltersRow extends StatelessWidget {
  final AttendanceController controller;
  const FiltersRow({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      color: AppColors.surface,
      child: Row(
        children: [
          Obx(
            () => SummaryChip(
              label: 'Total',
              value: uniqueEmployees(controller.logs),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10.0),
          Obx(() {
            final summary = controller.computeSummary();
            final presentCount = summary.values.where((v) {
              final logs = v['logs'] as List;
              return logs.any((l) => l.punchType == PunchType.in_);
            }).length;
            return SummaryChip(
              label: 'Present',
              value: presentCount,
              color: AppColors.success,
            );
          }),
          const Spacer(),
          SriButton(
            label: "Export",
            onPressed: () => controller.showExportMenu(context),
            icon: Icons.download_rounded,
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  int uniqueEmployees(List logs) =>
      logs.map((l) => l.employeeId).toSet().length;
}
