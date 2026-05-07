import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/attendance_log_model.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/attendance/widgets/punch_cell.dart';
import 'package:sri_hr/presentation/attendance/widgets/punch_form_dialog.dart';
import 'package:sri_hr/presentation/attendance/widgets/th.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';

class PunchTableView extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final AttendanceController controller;
  final AuthController auth;
  const PunchTableView({
    super.key,
    required this.rows,
    required this.controller,
    required this.auth,
  });

  String fmtTime(AttendanceLogModel? log) {
    if (log == null) return '—';
    return '${log.punchTime.hour.toString().padLeft(2, '0')}:${log.punchTime.minute.toString().padLeft(2, '0')}';
  }

  String totalHrs(AttendanceLogModel? i, AttendanceLogModel? o) {
    if (i == null || o == null) return '—';
    final mins = o.punchTime.difference(i.punchTime).inMinutes;
    return mins > 0 ? '${mins ~/ 60}h ${mins % 60}m' : '—';
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 20.0 : 10.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: isWide ? MediaQuery.of(context).size.width * 0.8 : 850,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: TH('Employee')),
                    Expanded(flex: 2, child: TH('Date')),
                    Expanded(flex: 2, child: TH('IN Time')),
                    Expanded(flex: 2, child: TH('OUT Time')),
                    Expanded(flex: 2, child: TH('Total Hrs')),
                    SizedBox(width: 50, child: TH('Edit', center: true)),
                  ],
                ),
              ),
              ...rows.map((row) {
                final emp = row['employee'] as dynamic;
                final date = row['date'] as DateTime;
                final inLog = row['inLog'] as AttendanceLogModel?;
                final outLog = row['outLog'] as AttendanceLogModel?;
                final empName = emp?.fullName as String? ?? 'Unknown';
                final empCode = emp?.employeeCode as String? ?? '';
                final picUrl = emp?.profilePicture as String?;
                final initial = empName.isNotEmpty
                    ? empName[0].toUpperCase()
                    : '?';
                final dateStr =
                    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 10.0,
                  ),
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
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.warning.withOpacity(
                                0.15,
                              ),
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
                      Expanded(
                        flex: 2,
                        child: Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: PunchCell(
                          time: fmtTime(inLog),
                          type: 'IN',
                          exists: inLog != null,
                          isManual: inLog?.isManual ?? false,
                          canDelete:
                              auth.canDelete('punch_adjustment') &&
                              inLog != null,
                          onDelete: inLog != null
                              ? () => controller.deleteLog(inLog.id)
                              : () {},
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: PunchCell(
                          time: fmtTime(outLog),
                          type: 'OUT',
                          exists: outLog != null,
                          isManual: outLog?.isManual ?? false,
                          canDelete:
                              auth.canDelete('punch_adjustment') &&
                              outLog != null,
                          onDelete: outLog != null
                              ? () => controller.deleteLog(outLog.id)
                              : () {},
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          totalHrs(inLog, outLog),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: inLog != null && outLog != null
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: auth.canEdit('punch_adjustment')
                            ? GestureDetector(
                                onTap: () => showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => PunchFormDialog(
                                    controller: controller,
                                    prefillRow: row,
                                  ),
                                ),
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
                    ],
                  ),
                );
              }),
              // Container(
              //   height: 8,
              //   decoration: BoxDecoration(
              //     color: AppColors.surfaceVariant,
              //     borderRadius: const BorderRadius.vertical(
              //       bottom: Radius.circular(12),
              //     ),
              //     border: Border.all(color: AppColors.border),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
