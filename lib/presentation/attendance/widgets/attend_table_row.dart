import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/attendance_log_model.dart';
import 'package:sri_hr/presentation/attendance/widgets/time_tag.dart';

class AttendTableRow extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool canDelete;
  final void Function(String) onDeleteLog;
  const AttendTableRow({
    super.key,
    required this.row,
    required this.canDelete,
    required this.onDeleteLog,
  });

  String fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final emp = row['employee'] as dynamic;
    final date = row['date'] as DateTime;
    final inLogs = row['inLogs'] as List<AttendanceLogModel>;
    final outLogs = row['outLogs'] as List<AttendanceLogModel>;
    final totalMins = row['totalMins'] as int;
    final empName = emp?.fullName as String? ?? 'Unknown';
    final empCode = emp?.employeeCode as String? ?? '';
    final deptName = emp?.department?.name as String? ?? '';
    final picUrl = emp?.profilePicture as String?;
    final initial = empName.isNotEmpty ? empName[0].toUpperCase() : '?';
    final totalHrs = totalMins > 0
        ? '${totalMins ~/ 60}h ${totalMins % 60}m'
        : '—';
    final isGood = totalMins >= 480; // 8+ hours
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Employee
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: picUrl != null ? NetworkImage(picUrl) : null,
                  child: picUrl == null
                      ? Text(
                          initial,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        empName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$empCode${deptName.isNotEmpty ? ' · $deptName' : ''}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Date
          Expanded(
            flex: 2,
            child: Text(
              fmtDate(date),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // IN times
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: inLogs
                  .map(
                    (l) => TimeTag(
                      time: fmtTime(l.punchTime),
                      color: AppColors.success,
                      icon: Icons.login_rounded,
                      isManual: l.isManual,
                      canDelete: canDelete,
                      onDelete: () => onDeleteLog(l.id),
                    ),
                  )
                  .toList(),
            ),
          ),
          // OUT times
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: outLogs
                  .map(
                    (l) => TimeTag(
                      time: fmtTime(l.punchTime),
                      color: AppColors.error,
                      icon: Icons.logout_rounded,
                      isManual: l.isManual,
                      canDelete: canDelete,
                      onDelete: () => onDeleteLog(l.id),
                    ),
                  )
                  .toList(),
            ),
          ),
          // Total hours
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: totalMins > 0
                    ? (isGood ? AppColors.success : AppColors.warning)
                          .withOpacity(0.08)
                    : AppColors.border.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                totalHrs,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: totalMins > 0
                      ? (isGood ? AppColors.success : AppColors.warning)
                      : AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}
