import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/leave_request_model.dart';
import 'package:sri_hr/presentation/leave/widgets/info_badge.dart';
import 'package:sri_hr/widgets/status_badge.dart';

class LeaveCard extends StatelessWidget {
  final LeaveRequestModel leave;
  final bool canApprove;
  final bool canDelete;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  const LeaveCard({
    super.key,
    required this.leave,
    required this.canApprove,
    required this.canDelete,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  Color get borderColor => switch (leave.status) {
    LeaveStatus.approved => AppColors.success.withOpacity(0.4),
    LeaveStatus.rejected => AppColors.error.withOpacity(0.4),
    LeaveStatus.pending => AppColors.warning.withOpacity(0.3),
  };

  @override
  Widget build(BuildContext context) {
    final emp = leave.employee;
    final empName = emp?.fullName ?? "Unknown Employee";
    final empCode = emp?.employeeCode ?? '';
    final deptName = emp?.department?.name ?? '';
    final roleName = emp?.role?.name ?? '';
    final initial = empName.isNotEmpty ? empName[0].toUpperCase() : '?';

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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: emp?.profilePicture != null
                      ? NetworkImage(emp!.profilePicture!)
                      : null,
                  child: emp?.profilePicture == null
                      ? Text(
                          initial,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Employee info
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
                        spacing: 8,
                        children: [
                          if (empCode.isNotEmpty)
                            InfoBadge(empCode, AppColors.primary),
                          if (deptName.isNotEmpty)
                            InfoBadge(
                              deptName,
                              AppColors.textMuted,
                              border: true,
                            ),
                          if (roleName.isNotEmpty)
                            InfoBadge(
                              roleName,
                              AppColors.textMuted,
                              border: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: leave.status.name),
              ],
            ),
          ),

          // ── Divider ──────────────────────────────
          const Divider(height: 1, color: AppColors.border),

          // ── Date + Days row ──────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.date_range_rounded,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  fmt(leave.fromDate),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  fmt(leave.toDate),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${leave.days} day${leave.days != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Reason ───────────────────────────────
          if (leave.reason?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notes_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      leave.reason!,
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
          // ── Approved by ──────────────────────────
          if (leave.status != LeaveStatus.pending && leave.approvedAt != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  Icon(
                    leave.status == LeaveStatus.approved
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 13,
                    color: leave.status == LeaveStatus.approved
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${leave.status == LeaveStatus.approved ? 'Approved' : 'Rejected'} on '
                    '${fmt(leave.approvedAt!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: leave.status == LeaveStatus.approved
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          // ── Actions ──────────────────────────────
          if (canApprove && leave.status == LeaveStatus.pending) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
            const SizedBox(height: 12),
            // Delete button (bottom right)
            if (canDelete)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 12, 12),
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
              const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  String fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
