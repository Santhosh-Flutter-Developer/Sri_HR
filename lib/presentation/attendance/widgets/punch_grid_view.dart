import 'package:flutter/material.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/attendance_log_model.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
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

  String fmtT(AttendanceLogModel l) =>
      '${l.punchTime.hour.toString().padLeft(2, '0')}:${l.punchTime.minute.toString().padLeft(2, '0')}';

  String fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
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
              final empName = emp?.fullName as String? ?? 'Unknown';
              final empCode = emp?.employeeCode as String? ?? '';
              final picUrl = emp?.profilePicture as String?;
              final initial = empName.isNotEmpty ? empName[0].toUpperCase() : '?';

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
                        // ── Header ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.warning.withOpacity(0.15),
                                backgroundImage: picUrl != null ? NetworkImage(picUrl) : null,
                                child: picUrl == null
                                    ? Text(initial,
                                        style: const TextStyle(
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ))
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(empName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis),
                                    Text(empCode,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.w600,
                                        )),
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
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.edit_rounded,
                                        size: 14, color: AppColors.warning),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // ── Date bar ──
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          color: AppColors.surfaceVariant,
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 11, color: AppColors.textMuted),
                              const SizedBox(width: 5),
                              Text(fmtDate(date),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  )),
                            ],
                          ),
                        ),

                        // ── Punch rows ──
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              // Column headers
                              Row(
                                children: [
                                  _colHeader('IN', AppColors.success),
                                  const SizedBox(width: 8),
                                  _colHeader('OUT', AppColors.error),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Pair rows side by side
                              ...List.generate(
                                [inLogs.length, outLogs.length].reduce((a, b) => a > b ? a : b),
                                (idx) {
                                  final inLog = idx < inLogs.length ? inLogs[idx] : null;
                                  final outLog = idx < outLogs.length ? outLogs[idx] : null;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: inLog != null
                                              ? _punchChip(
                                                  fmtT(inLog),
                                                  AppColors.success,
                                                  inLog.isManual,
                                                  auth.canDelete('punch_adjustment'),
                                                  () => controller.deleteLog(inLog.id),
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: outLog != null
                                              ? _punchChip(
                                                  fmtT(outLog),
                                                  AppColors.error,
                                                  outLog.isManual,
                                                  auth.canDelete('punch_adjustment'),
                                                  () => controller.deleteLog(outLog.id),
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              if (inLogs.isEmpty && outLogs.isEmpty)
                                const Text('No records',
                                    style: TextStyle(
                                        fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
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
  }

  Widget _colHeader(String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      );

  Widget _punchChip(
    String time,
    Color color,
    bool isManual,
    bool canDelete,
    VoidCallback onDelete,
  ) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Row(
              children: [
                if (isManual)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('M',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning,
                        )),
                  ),
                if (canDelete) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(Icons.close_rounded,
                        size: 12, color: AppColors.error.withOpacity(0.6)),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
}