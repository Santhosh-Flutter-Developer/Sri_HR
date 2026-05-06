import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/attendance_log_model.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/attendance/widgets/mini_punch_tag.dart';
import 'package:sri_hr/presentation/attendance/widgets/punch_form_dialog.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';

class PunchGridView extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final AttendanceController controller;
  final AuthController auth;
  const PunchGridView({
    super.key,
    required this.rows,
    required this.controller,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    final cross = MediaQuery.of(context).size.width > 900 ? 3 : 2;
    return GridView.builder(
      padding: const EdgeInsets.all(20.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.2,
      ),
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final row = rows[i];
        final emp = row['employee'] as dynamic;
        final date = row['date'] as DateTime;
        final inLog = row['inLog'] as AttendanceLogModel?;
        final outLog = row['outLog'] as AttendanceLogModel?;
        final empName = emp?.fullName as String? ?? 'Unknown';
        final empCode = emp?.employeeCode as String? ?? '';
        final picUrl = emp?.profilePicture as String?;
        final initial = empName.isNotEmpty ? empName[0].toUpperCase() : '?';
        final dateStr =
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
        final fmtT = (AttendanceLogModel? l) => l != null
            ? '${l.punchTime.hour.toString().padLeft(2, '0')}:${l.punchTime.minute.toString().padLeft(2, '0')}'
            : '—';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.warning.withOpacity(0.15),
                    backgroundImage: picUrl != null
                        ? NetworkImage(picUrl)
                        : null,
                    child: picUrl == null
                        ? Text(
                            initial,
                            style: const TextStyle(
                              color: AppColors.warning,
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
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          empCode,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (auth.canEdit('punch_adjustment'))
                    GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => PunchFormDialog(
                          controller: controller,
                          prefillRow: row,
                        ),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                    ),
                ],
              ),
              const Divider(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  MiniPunchTag(
                    'IN',
                    fmtT(inLog),
                    AppColors.success,
                    inLog?.isManual ?? false,
                  ),
                  const SizedBox(width: 8),
                  MiniPunchTag(
                    'OUT',
                    fmtT(outLog),
                    AppColors.error,
                    outLog?.isManual ?? false,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
