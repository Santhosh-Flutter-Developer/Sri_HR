import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/attendance_log_model.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/attendance/widgets/hours_chip.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';

class AttendanceTable extends StatelessWidget {
  final AttendanceController controller;
  const AttendanceTable({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final summary = controller.computeSummary();
    final entries = summary.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final entry = entries[i];
        final data = entry.value;
        final emp = data["employee"];
        final logs = data["logs"] as List<AttendanceLogModel>;
        final totalHours = (data["total_hours"] as double).toStringAsFixed(1);
        final auth = Get.find<AuthController>();
        return Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: AppColors.border),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            leading: CircleAvatar(
              radius: 20.0,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                emp?.fullName.substring(0, 1) ?? '?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(
              emp?.fullName ?? 'Unknown',
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${emp?.employeeCode ?? ''} • ${emp?.department?.name ?? ''}',
              style: const TextStyle(
                fontSize: 11.0,
                color: AppColors.textMuted,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HoursChip(hours: double.tryParse(totalHours) ?? 0),
                const SizedBox(width: 8.0),
                const Icon(
                  Icons.expand_more,
                  size: 18.0,
                  color: AppColors.textMuted,
                ),
              ],
            ),
            children: [
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ...logs.map(
                      (log) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: log.punchType == PunchType.in_
                                    ? AppColors.success.withOpacity(0.1)
                                    : AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    log.punchType == PunchType.in_
                                        ? Icons.login_rounded
                                        : Icons.logout_rounded,
                                    size: 12,
                                    color: log.punchType == PunchType.in_
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    log.punchType == PunchType.in_
                                        ? 'IN'
                                        : 'OUT',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: log.punchType == PunchType.in_
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              formatTime(log.punchTime),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (log.isManual) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Manual',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            if (auth.canDelete('attendance_report'))
                              GestureDetector(
                                onTap: () => controller.deleteLog(log.id),
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
