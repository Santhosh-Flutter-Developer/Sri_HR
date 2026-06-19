// lib/presentation/attendance/widgets/grid_view.dart
// Grid card shows all fields: punch records, expected/actual/diff hours,
// late arrival (hh:mm), permission (timings + status), leave status, status badge.
import 'package:flutter/material.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/attendance_log_model.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';

class GridedView extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final AttendanceController controller;
  final AuthController auth;
  const GridedView({super.key, required this.rows, required this.controller, required this.auth});

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  String _fmtMins(int mins) {
    if (mins <= 0) return '—';
    return '${mins ~/ 60}h ${(mins % 60).toString().padLeft(2,'0')}m';
  }
  String _fmtDiff(int diff) {
    if (diff == 0) return '±0h 00m';
    final sign = diff > 0 ? '+' : '-';
    final a = diff.abs();
    return '$sign${(a ~/ 60).toString().padLeft(2,'0')}h ${(a % 60).toString().padLeft(2,'0')}m';
  }
  // Late arrival formatted as Xh XXm (consistent with Expected / Actual columns)
  String _fmtLate(int mins) =>
      '${mins ~/ 60}h ${(mins % 60).toString().padLeft(2,'0')}m';
  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    if (rows.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 40, color: AppColors.textMuted),
            SizedBox(height: 10),
            Text('No attendance records', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(isWide ? 16 : 10),
      children: [
        ResponsiveGridRow(
          children: rows.asMap().entries.map((entry) {
            final row       = entry.value;
            final emp       = row['employee'] as dynamic;
            final date      = row['date'] as DateTime;
            final inLogs    = List<AttendanceLogModel>.from(row['inLogs'] as List)
                ..sort((a, b) => a.punchTime.compareTo(b.punchTime));
            final outLogs   = List<AttendanceLogModel>.from(row['outLogs'] as List)
                ..sort((a, b) => a.punchTime.compareTo(b.punchTime));
            final totalMins    = row['totalMins']    as int? ?? 0;
            final isAbsent     = row['isAbsent']     as bool? ?? false;
            final expectedMins = row['expectedMins'] as int?;
            final lateMinutes  = row['lateMinutes']  as int?;
            final permStatus   = row['permStatus']   as String?;
            final permTimings  = row['permTimings']  as String?;
            final leaveStatus  = row['leaveStatus']  as String?;

            final diffMins = (expectedMins != null && expectedMins > 0)
                ? (totalMins - expectedMins) : null;

            final empName  = (emp?.fullName as String?) ?? 'Unknown';
            final empCode  = (emp?.employeeCode as String?) ?? '';
            final deptName = (emp?.department?.name as String?) ?? '';
            final picUrl   = emp?.profilePicture as String?;
            final initial  = empName.isNotEmpty ? empName[0].toUpperCase() : '?';

            // Status
            final String statusLabel;
            final Color  statusColor;
            if (leaveStatus == 'approved' && inLogs.isEmpty) {
              statusLabel = 'Leave'; statusColor = AppColors.info;
            } else if (isAbsent) {
              statusLabel = 'Absent'; statusColor = AppColors.error;
            } else {
              statusLabel = 'Present'; statusColor = AppColors.success;
            }

            Color actualColor = AppColors.textSecondary;
            if (totalMins > 0 && expectedMins != null && expectedMins > 0) {
              final pct = totalMins / expectedMins;
              actualColor = pct >= 1.0 ? AppColors.success : pct >= 0.75 ? AppColors.warning : AppColors.error;
            }

            final borderColor = isAbsent
                ? AppColors.error.withOpacity(0.30)
                : leaveStatus == 'approved'
                    ? AppColors.info.withOpacity(0.30)
                    : totalMins == 0
                        ? AppColors.border
                        : (expectedMins != null && totalMins >= expectedMins)
                            ? AppColors.success.withOpacity(0.35)
                            : AppColors.warning.withOpacity(0.35);

            return ResponsiveGridCol(
              xl: 4, lg: 4, md: 6, xs: 12, sm: 12,
              child: Padding(
                padding: EdgeInsets.only(right: isWide ? 8.0 : 0.0, bottom: 10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
                        blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Header: avatar + name + actual hours ───────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            backgroundImage: picUrl != null ? NetworkImage(picUrl) : null,
                            child: picUrl == null
                                ? Text(initial, style: const TextStyle(color: AppColors.primary,
                                    fontWeight: FontWeight.w800, fontSize: 13))
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(empName, style: const TextStyle(fontWeight: FontWeight.w700,
                                  fontSize: 13, color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis),
                              Text('$empCode${deptName.isNotEmpty ? ' · $deptName' : ''}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.primary,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          )),
                          // Actual hours badge
                          if (totalMins > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: actualColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(_fmtMins(totalMins),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                                      color: actualColor)),
                            ),
                        ]),
                      ),

                      // ── Date + Status bar ──────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        color: AppColors.surfaceVariant,
                        child: Row(children: [
                          const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 5),
                          Text(_fmtDate(date), style: const TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          const Spacer(),
                          _statusDot(statusLabel, statusColor),
                        ]),
                      ),

                      // ── Hours summary row ──────────────────────────────────
                      if (expectedMins != null || diffMins != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: Row(children: [
                            if (expectedMins != null) ...[
                              _miniStat('Expected', _fmtMins(expectedMins), AppColors.textSecondary),
                              const SizedBox(width: 8),
                            ],
                            if (diffMins != null)
                              _miniStat('Diff',
                                  _fmtDiff(diffMins),
                                  diffMins >= 0 ? AppColors.success : AppColors.error),
                          ]),
                        ),

                      // ── First In / Last Out quick row ──────────────────────
                      if (inLogs.isNotEmpty || outLogs.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                          child: Row(children: [
                            if (inLogs.isNotEmpty) ...[
                              _quickPunch('First In',
                                  _fmtTime(inLogs.first.punchTime), AppColors.success),
                              const SizedBox(width: 8),
                            ],
                            if (outLogs.isNotEmpty)
                              _quickPunch('Last Out',
                                  _fmtTime(outLogs.last.punchTime), AppColors.error),
                          ]),
                        ),

                      // ── Punch records table ────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(children: [
                          Row(children: [
                            _colHdr('IN', AppColors.success),
                            const SizedBox(width: 8),
                            _colHdr('OUT', AppColors.error),
                          ]),
                          const SizedBox(height: 6),
                          ...List.generate(
                            [inLogs.length, outLogs.length].fold(0, (a, b) => a > b ? a : b),
                            (idx) {
                              final inLog  = idx < inLogs.length  ? inLogs[idx]  : null;
                              final outLog = idx < outLogs.length ? outLogs[idx] : null;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Row(children: [
                                  Expanded(child: inLog != null
                                      ? _punchChip(_fmtTime(inLog.punchTime), AppColors.success,
                                          inLog.isManual, auth.canDelete('attendance_report'),
                                          () => controller.confirmDelete(context, inLog.id))
                                      : const SizedBox.shrink()),
                                  const SizedBox(width: 8),
                                  Expanded(child: outLog != null
                                      ? _punchChip(_fmtTime(outLog.punchTime), AppColors.error,
                                          outLog.isManual, auth.canDelete('attendance_report'),
                                          () => controller.confirmDelete(context, outLog.id))
                                      : const SizedBox.shrink()),
                                ]),
                              );
                            },
                          ),
                          if (inLogs.isEmpty && outLogs.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text('No records',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ),
                        ]),
                      ),

                      // ── Footer: Late / Permission / Leave ──────────────────
                      if (lateMinutes != null || permStatus != null || leaveStatus != null)
                        Container(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: AppColors.border)),
                          ),
                          child: Wrap(
                            spacing: 6, runSpacing: 5,
                            children: [
                              // Late
                              if (lateMinutes != null && lateMinutes > 0)
                                _footerBadge(
                                    Icons.timer_off_rounded,
                                    'Late ${_fmtLate(lateMinutes)}',
                                    AppColors.warning),
                              if (lateMinutes != null && lateMinutes == 0 && inLogs.isNotEmpty)
                                _footerBadge(Icons.check_circle_outline_rounded,
                                    'On Time', AppColors.success),

                              // Permission
                              if (permStatus != null) ...[
                                if (permTimings != null && permTimings.isNotEmpty)
                                  _footerBadge(Icons.more_time_rounded,
                                      permTimings, AppColors.textSecondary),
                                _footerBadge(Icons.badge_outlined,
                                    'Perm: ${_cap(permStatus)}', _permColor(permStatus)),
                              ],

                              // Leave
                              if (leaveStatus != null)
                                _footerBadge(Icons.event_busy_rounded,
                                    'Leave: ${_cap(leaveStatus)}', _leaveColor(leaveStatus)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Small widget builders ────────────────────────────────────────────────
  Widget _statusDot(String label, Color color) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 5, height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ]);

  Widget _miniStat(String label, String value, Color color) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ]);

  Widget _quickPunch(String label, String time, Color color) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(7)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
            Text(time, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ));

  Widget _colHdr(String label, Color color) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
        child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ));

  Widget _punchChip(String time, Color color, bool isManual, bool canDelete, VoidCallback onDelete) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
            color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.25))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(time, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            Row(children: [
              if (isManual)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('M', style: TextStyle(fontSize: 8,
                      fontWeight: FontWeight.w800, color: AppColors.warning)),
                ),
              if (canDelete) ...[
                const SizedBox(width: 4),
                GestureDetector(onTap: onDelete,
                    child: Icon(Icons.close_rounded, size: 12,
                        color: AppColors.error.withOpacity(0.6))),
              ],
            ]),
          ],
        ),
      );

  Widget _footerBadge(IconData icon, String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.09), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]));

  Color _permColor(String s) {
    switch (s.toLowerCase()) {
      case 'approved': return AppColors.success;
      case 'pending':  return AppColors.warning;
      case 'rejected': return AppColors.error;
      default:         return AppColors.textMuted;
    }
  }

  Color _leaveColor(String s) {
    switch (s.toLowerCase()) {
      case 'approved': return AppColors.info;
      case 'pending':  return AppColors.warning;
      case 'rejected': return AppColors.error;
      default:         return AppColors.textMuted;
    }
  }
}