import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/leave_request_model.dart';
import 'package:sri_hr/data/models/permission_request_model.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/permission_request/controller/permission_request_controller.dart';
import 'package:sri_hr/widgets/status_badge.dart';

class PermissionRequestCard extends StatelessWidget {
  final PermissionRequestModel req;
  final PermissionRequestController controller;
  const PermissionRequestCard({
    super.key,
    required this.req,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              (req.employee?.fullName ?? 'U').substring(0, 1),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.employee?.fullName ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${req.requestDate.toIso8601String().substring(0, 10)}  •  ${req.fromTime} – ${req.toTime}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                if (req.reason?.isNotEmpty == true)
                  Text(
                    req.reason!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(status: req.status.name),
              if (auth.canEdit('permission_request') &&
                  req.status == LeaveStatus.pending) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => controller.reject(req.id),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.error,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => controller.approve(req.id),
                      child: const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
