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
                final inLogs = row['inLogs'] as List<AttendanceLogModel>;
                final outLogs = row['outLogs'] as List<AttendanceLogModel>;
                final empName = emp?.fullName as String? ?? 'Unknown';
                final empCode = emp?.employeeCode as String? ?? '';
                final picUrl = emp?.profilePicture as String?;
                final initial = empName.isNotEmpty
                    ? empName[0].toUpperCase()
                    : '?';
                final dateStr =
                    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

                // total: first IN → last OUT
                final inLog = inLogs.isNotEmpty ? inLogs.first : null;
                final outLog = outLogs.isNotEmpty ? outLogs.last : null;
                final totalMins = row['totalMins'] as int? ?? 0;
                final totalHrsStr = totalMins > 0
                    ? '${totalMins ~/ 60}h ${totalMins % 60}m'
                    : '—';

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Employee
                      Expanded(
                        flex: 3,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                      // Date
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      // IN punches — all of them
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: inLogs.isEmpty
                              ? [
                                  const Text(
                                    '—',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ]
                              : inLogs
                                    .map(
                                      (l) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: PunchCell(
                                          time: fmtTime(l),
                                          type: 'IN',
                                          exists: true,
                                          isManual: l.isManual,
                                          canDelete: auth.canDelete(
                                            'punch_adjustment',
                                          ),
                                          onDelete: () =>
                                              controller.deleteLog(l.id),
                                        ),
                                      ),
                                    )
                                    .toList(),
                        ),
                      ),
                      // OUT punches — all of them
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: outLogs.isEmpty
                              ? [
                                  const Text(
                                    '—',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ]
                              : outLogs
                                    .map(
                                      (l) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: PunchCell(
                                          time: fmtTime(l),
                                          type: 'OUT',
                                          exists: true,
                                          isManual: l.isManual,
                                          canDelete: auth.canDelete(
                                            'punch_adjustment',
                                          ),
                                          onDelete: () =>
                                              controller.deleteLog(l.id),
                                        ),
                                      ),
                                    )
                                    .toList(),
                        ),
                      ),
                      // Total hrs (first IN → last OUT)
                      Expanded(
                        flex: 2,
                        child: Text(
                          totalHrsStr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: totalMins > 0
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                      // Edit button
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
