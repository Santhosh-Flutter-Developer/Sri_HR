import 'package:flutter/material.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/attendance_log_model.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/attendance/widgets/grid_time_row.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';

class GridedView extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final AttendanceController controller;
  final AuthController auth;
  const GridedView({
    super.key,
    required this.rows,
    required this.controller,
    required this.auth,
  });

  String fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    final crossAxis = MediaQuery.of(context).size.width > 1100
        ? 4
        : MediaQuery.of(context).size.width > 700
        ? 3
        : 2;
    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: isWide ? 24.0 : 10.0,
            left: isWide ? 24.0 : 10.0,
            right: isWide ? 24.0 : 10.0,
            bottom: 10.0,
          ),
          child: ResponsiveGridRow(
            children: List.generate(rows.length, (i) {
              final row = rows[i];
              final emp = row['employee'] as dynamic;
              final date = row['date'] as DateTime;
              final inLogs = row['inLogs'] as List<AttendanceLogModel>;
              final outLogs = row['outLogs'] as List<AttendanceLogModel>;
              final totalMins = row['totalMins'] as int;
              final empName = emp?.fullName as String? ?? 'Unknown';
              final empCode = emp?.employeeCode as String? ?? '';
              final picUrl = emp?.profilePicture as String?;
              final initial = empName.isNotEmpty
                  ? empName[0].toUpperCase()
                  : '?';
              final isGood = totalMins >= 480;
              final totalHrs = totalMins > 0
                  ? '${totalMins ~/ 60}h ${totalMins % 60}m'
                  : '—';
              final borderColor = totalMins == 0
                  ? AppColors.border
                  : isGood
                  ? AppColors.success.withOpacity(0.4)
                  : AppColors.warning.withOpacity(0.4);
              return ResponsiveGridCol(
                xl: 4,
                lg: 4,
                md: 6,
                xs: 12,
                sm: 12,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: isWide ? 8.0 : 0.0,
                    bottom: 10.0,
                  ),
                  child: Container(
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
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Employee header
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              backgroundImage: picUrl != null
                                  ? NetworkImage(picUrl)
                                  : null,
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
                                    maxLines: 1,
                                  ),
                                  Text(
                                    empCode,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (totalMins > 0
                                            ? (isGood
                                                  ? AppColors.success
                                                  : AppColors.warning)
                                            : AppColors.border)
                                        .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                totalHrs,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: totalMins > 0
                                      ? (isGood
                                            ? AppColors.success
                                            : AppColors.warning)
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Date
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              fmtDate(date),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                       const Divider(height: 12),
// All IN punches
...inLogs.map((l) => Padding(
  padding: const EdgeInsets.only(bottom: 4),
  child: GridTimeRow(
    icon: Icons.login_rounded,
    color: AppColors.success,
    type: 'IN',
    time: fmtTime(l.punchTime),
    isManual: l.isManual,
  ),
)),
// All OUT punches
...outLogs.map((l) => Padding(
  padding: const EdgeInsets.only(bottom: 4),
  child: GridTimeRow(
    icon: Icons.logout_rounded,
    color: AppColors.error,
    type: 'OUT',
    time: fmtTime(l.punchTime),
    isManual: l.isManual,
  ),
)),
if (inLogs.isEmpty && outLogs.isEmpty)
  const Text(
    'No records',
    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
  ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
    /*GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxis,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.1,
      ),
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final row = rows[i];
        final emp = row['employee'] as dynamic;
        final date = row['date'] as DateTime;
        final inLogs = row['inLogs'] as List<AttendanceLogModel>;
        final outLogs = row['outLogs'] as List<AttendanceLogModel>;
        final totalMins = row['totalMins'] as int;
        final empName = emp?.fullName as String? ?? 'Unknown';
        final empCode = emp?.employeeCode as String? ?? '';
        final picUrl = emp?.profilePicture as String?;
        final initial = empName.isNotEmpty ? empName[0].toUpperCase() : '?';
        final isGood = totalMins >= 480;
        final totalHrs = totalMins > 0
            ? '${totalMins ~/ 60}h ${totalMins % 60}m'
            : '—';
        final borderColor = totalMins == 0
            ? AppColors.border
            : isGood
            ? AppColors.success.withOpacity(0.4)
            : AppColors.warning.withOpacity(0.4);
        return Container(
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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employee header
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: picUrl != null
                        ? NetworkImage(picUrl)
                        : null,
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
                          maxLines: 1,
                        ),
                        Text(
                          empCode,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (totalMins > 0
                                  ? (isGood
                                        ? AppColors.success
                                        : AppColors.warning)
                                  : AppColors.border)
                              .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      totalHrs,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: totalMins > 0
                            ? (isGood ? AppColors.success : AppColors.warning)
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Date
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    fmtDate(date),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Divider(height: 12),
              // IN / OUT
              if (inLogs.isNotEmpty)
                GridTimeRow(
                  icon: Icons.login_rounded,
                  color: AppColors.success,
                  type: 'IN',
                  time: fmtTime(inLogs.first.punchTime),
                  isManual: inLogs.first.isManual,
                ),
              if (outLogs.isNotEmpty)
                GridTimeRow(
                  icon: Icons.logout_rounded,
                  color: AppColors.error,
                  type: 'OUT',
                  time: fmtTime(outLogs.last.punchTime),
                  isManual: outLogs.last.isManual,
                ),
              if (inLogs.isEmpty && outLogs.isEmpty)
                const Text(
                  'No records',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
            ],
          ),
        );
      },
    );*/
  }
}
