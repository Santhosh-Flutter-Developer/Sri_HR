import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/attendance_log_model.dart';

class TablesRow extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool canDelete;
  final VoidCallback onDeleteIn, onDeleteOut;
  final VoidCallback? onEdit;
  const TablesRow({
    super.key,
    required this.row,
    required this.canDelete,
    required this.onDeleteIn,
    required this.onDeleteOut,
    this.onEdit,
  });

  String _fmtTime(AttendanceLogModel? log) {
    if (log == null) return '—';
    final dt = log.punchTime;
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _totalHrs(AttendanceLogModel? inLog, AttendanceLogModel? outLog) {
    if (inLog == null || outLog == null) return '—';
    final mins = outLog.punchTime.difference(inLog.punchTime).inMinutes;
    if (mins <= 0) return '—';
    return '${mins ~/ 60}h ${mins % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final emp = row['employee'] as dynamic;
    final date = row['date'] as DateTime;
    final inLog = row['inLog'] as AttendanceLogModel?;
    final outLog = row['outLog'] as AttendanceLogModel?;

    final empName = emp?.fullName?.isNotEmpty == true
        ? emp.fullName as String
        : 'Unknown';
    final empCode = emp?.employeeCode as String? ?? '';
    final initial = empName[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          bottom: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          // Employee
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.warning.withOpacity(0.15),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
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
                      if (empCode.isNotEmpty)
                        Text(
                          empCode,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
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
              '${date.day.toString().padLeft(2, '0')} '
              '${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // IN Time
          Expanded(
            flex: 2,
            child: TimeCell(
              time: _fmtTime(inLog),
              type: 'IN',
              exists: inLog != null,
              onDelete: canDelete && inLog != null ? onDeleteIn : null,
            ),
          ),
          // OUT Time
          Expanded(
            flex: 2,
            child: TimeCell(
              time: _fmtTime(outLog),
              type: 'OUT',
              exists: outLog != null,
              onDelete: canDelete && outLog != null ? onDeleteOut : null,
            ),
          ),
          // Total Hours
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: inLog != null && outLog != null
                    ? AppColors.success.withOpacity(0.08)
                    : AppColors.border.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _totalHrs(inLog, outLog),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: inLog != null && outLog != null
                      ? AppColors.success
                      : AppColors.textMuted,
                ),
              ),
            ),
          ),
          // Edit action
          SizedBox(
            width: 60,
            child: Center(
              child: onEdit != null
                  ? GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 15,
                          color: AppColors.warning,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class TimeCell extends StatelessWidget {
  final String time;
  final String type;
  final bool exists;
  final VoidCallback? onDelete;
  const TimeCell({
    super.key,
    required this.time,
    required this.type,
    required this.exists,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (!exists) {
      return Text(
        '—',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      );
    }
    final color = type == 'IN' ? AppColors.success : AppColors.error;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type == 'IN' ? Icons.login_rounded : Icons.logout_rounded,
                size: 11,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        if (onDelete != null) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close_rounded,
              size: 13,
              color: AppColors.error.withOpacity(0.7),
            ),
          ),
        ],
      ],
    );
  }
}
