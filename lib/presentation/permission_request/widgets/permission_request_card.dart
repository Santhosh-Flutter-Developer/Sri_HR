import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/leave_request_model.dart';
import 'package:sri_hr/data/models/permission_request_model.dart';
import 'package:sri_hr/presentation/permission_request/widgets/badge.dart';
import 'package:sri_hr/widgets/status_badge.dart';

class PermissionCard extends StatelessWidget {
  final PermissionRequestModel req;
  final bool canApprove, canDelete;
  final VoidCallback onApprove, onReject, onDelete;
  const PermissionCard({
    super.key,
    required this.req,
    required this.canApprove,
    required this.canDelete,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  Color get borderColor => switch (req.status) {
    LeaveStatus.approved => AppColors.success.withOpacity(0.4),
    LeaveStatus.rejected => AppColors.error.withOpacity(0.4),
    LeaveStatus.pending => AppColors.warning.withOpacity(0.3),
  };

  @override
  Widget build(BuildContext context) {
    final emp = req.employee;
    final empName = emp?.fullName.isNotEmpty == true
        ? emp!.fullName
        : 'Unknown Employee';
    final empCode = emp?.employeeCode ?? '';
    final deptName = emp?.department?.name ?? '';
    final roleName = emp?.role?.name ?? '';
    final initial = empName[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Employee row ────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.info.withOpacity(0.1),
                  backgroundImage: emp?.profilePicture != null
                      ? NetworkImage(emp!.profilePicture!)
                      : null,
                  child: emp?.profilePicture == null
                      ? Text(
                          initial,
                          style: const TextStyle(
                            color: AppColors.info,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        empName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 6,
                        children: [
                          if (empCode.isNotEmpty)
                            Badgee(empCode, AppColors.info),
                          if (deptName.isNotEmpty)
                            Badgee(deptName, AppColors.textMuted, border: true),
                          if (roleName.isNotEmpty)
                            Badgee(roleName, AppColors.textMuted, border: true),
                        ],
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: req.status.name),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // ── Date + Time row ─────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                // Date
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${req.requestDate.day.toString().padLeft(2, '0')} '
                        '${_monthShort(req.requestDate.month)} '
                        '${req.requestDate.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Time range
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${req.fromTime} – ${req.toTime}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ),
                if (req.minutes != null && req.minutes! > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${req.minutes} min',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Reason ──────────────────────────────
          if (req.reason?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.notes_rounded,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      req.reason!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // ── Actions ─────────────────────────────
          if (canApprove && req.status == LeaveStatus.pending) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded, size: 14),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_rounded, size: 14),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (canDelete)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 6, 12, 10),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  String _monthShort(int m) => [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];
}
