// lib/presentation/attendance/widgets/attend_table_row_v2.dart
import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/attendance_log_model.dart';
import 'package:sri_hr/presentation/attendance/widgets/table_view_v2.dart';
import 'package:sri_hr/presentation/attendance/widgets/time_tag.dart';

class AttendTableRowV2 extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool canDelete;
  final bool isAlternate;
  final void Function(String) onDeleteLog;

  const AttendTableRowV2({
    super.key, required this.row, required this.canDelete,
    required this.onDeleteLog, this.isAlternate = false,
  });

  static String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  static String _fmtMins(int mins) {
    if (mins <= 0) return '—';
    return '${mins ~/ 60}h ${(mins % 60).toString().padLeft(2,'0')}m';
  }

  static String _fmtDiff(int diff) {
    if (diff == 0) return '±0h 00m';
    final sign = diff > 0 ? '+' : '-';
    final a = diff.abs();
    return '$sign${a ~/ 60}h ${(a % 60).toString().padLeft(2,'0')}m';
  }

  // Late arrival formatted as Xh XXm (consistent with Expected / Actual columns)
  static String _fmtLate(int mins) {
    if (mins <= 0) return '';
    return '${mins ~/ 60}h ${(mins % 60).toString().padLeft(2,'0')}m';
  }

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final emp          = row['employee']     as dynamic;
    final date         = row['date']         as DateTime;
    final inLogs       = List<AttendanceLogModel>.from(row['inLogs'] as List);
    final outLogs      = List<AttendanceLogModel>.from(row['outLogs'] as List);
    final totalMins    = row['totalMins']    as int? ?? 0;
    final isAbsent     = row['isAbsent']     as bool? ?? false;
    final expectedMins = row['expectedMins'] as int?;
    final lateMinutes  = row['lateMinutes']  as int?;
    final permStatus   = row['permStatus']   as String?;
    final permTimings  = row['permTimings']  as String?; // e.g. "10:30–11:00"
    final leaveStatus  = row['leaveStatus']  as String?;

    final diffMins = (expectedMins != null && expectedMins > 0)
        ? (totalMins - expectedMins) : null;

    final firstIn = inLogs.isNotEmpty  ? _fmtTime(inLogs.first.punchTime) : '—';
    final lastOut = outLogs.isNotEmpty ? _fmtTime(outLogs.last.punchTime) : '—';

    final empName  = (emp?.fullName       as String?) ?? 'Unknown';
    final empCode  = (emp?.employeeCode   as String?) ?? '';
    final deptName = (emp?.department?.name as String?) ?? '';
    final picUrl   = emp?.profilePicture  as String?;
    final initial  = empName.isNotEmpty ? empName[0].toUpperCase() : '?';

    // Status: Leave > Present > Absent
    final String statusLabel;
    final Color  statusColor;
    if (leaveStatus == 'approved' && inLogs.isEmpty) {
      statusLabel = 'Leave'; statusColor = AppColors.info;
    } else if (isAbsent) {
      statusLabel = 'Absent'; statusColor = AppColors.error;
    } else {
      statusLabel = 'Present'; statusColor = AppColors.success;
    }

    // Actual hours color
    Color actualColor = AppColors.textSecondary;
    if (totalMins > 0 && expectedMins != null && expectedMins > 0) {
      final pct = totalMins / expectedMins;
      actualColor = pct >= 1.0 ? AppColors.success : pct >= 0.75 ? AppColors.warning : AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isAlternate ? AppColors.surfaceVariant : AppColors.surface,
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
          SizedBox(
            width: AttendCols.employee,
            child: Row(children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: picUrl != null ? NetworkImage(picUrl) : null,
                child: picUrl == null
                    ? Text(initial, style: const TextStyle(color: AppColors.primary,
                          fontWeight: FontWeight.w800, fontSize: 11))
                    : null,
              ),
              const SizedBox(width: 6),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(empName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12,
                          color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis),
                  Text('$empCode${deptName.isNotEmpty ? ' · $deptName' : ''}',
                      style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                      overflow: TextOverflow.ellipsis),
                ],
              )),
            ]),
          ),

          // Date
          SizedBox(width: AttendCols.date,
              child: _txt(_fmtDate(date), bold: true)),

          // First In
          SizedBox(width: AttendCols.firstIn,
              child: firstIn == '—' ? _txt('—') : _badge(firstIn, AppColors.success)),

          // Last Out
          SizedBox(width: AttendCols.lastOut,
              child: lastOut == '—' ? _txt('—') : _badge(lastOut, AppColors.error)),

          // In Records
          SizedBox(
            width: AttendCols.inRec,
            child: inLogs.isEmpty ? _txt('—') : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: inLogs.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: TimeTag(
                  time: _fmtTime(l.punchTime), color: AppColors.success,
                  icon: Icons.login_rounded, isManual: l.isManual,
                  canDelete: canDelete && (inLogs.last==l&& (inLogs.length>outLogs.length))  , onDelete: () => onDeleteLog(l.id),
                ),
              )).toList(),
            ),
          ),

          // Out Records
          SizedBox(
            width: AttendCols.outRec,
            child: outLogs.isEmpty ? _txt('—') : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: outLogs.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: TimeTag(
                  time: _fmtTime(l.punchTime), color: AppColors.error,
                  icon: Icons.logout_rounded, isManual: l.isManual,
                  canDelete: canDelete &&(outLogs.last==l && (outLogs.length>=inLogs.length)), onDelete: () => onDeleteLog(l.id),
                ),
              )).toList(),
            ),
          ),

          // Expected
          SizedBox(width: AttendCols.expected,
              child: _txt(expectedMins != null ? _fmtMins(expectedMins) : '—')),

          // Actual
          SizedBox(width: AttendCols.actual,
              child: totalMins > 0
                  ? _badge(_fmtMins(totalMins), actualColor)
                  : _txt('—')),

          // Difference
          SizedBox(width: AttendCols.diff,
              child: diffMins != null
                  ? _badge(_fmtDiff(diffMins),
                      diffMins >= 0 ? AppColors.success : AppColors.error)
                  : _txt('—')),

          // Late Arrival — hh:mm format
          SizedBox(
            width: AttendCols.late,
            child: (lateMinutes == null || lateMinutes == 0)
                ? (inLogs.isEmpty
                    ? _txt('—')
                    : _txt('On Time', color: AppColors.success, bold: true))
                : _badge(_fmtLate(lateMinutes), AppColors.warning),
          ),

          // Permission (timings + status)
          SizedBox(
            width: AttendCols.permission,
            child: permStatus == null
                ? _txt('—')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (permTimings != null && permTimings.isNotEmpty)
                        Text(permTimings,
                            style: const TextStyle(fontSize: 10,
                                color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      _badge(_cap(permStatus), _permColor(permStatus)),
                    ],
                  ),
          ),

          // Leave Status
          SizedBox(
            width: AttendCols.leave,
            child: leaveStatus != null
                ? _badge(_cap(leaveStatus), _leaveColor(leaveStatus))
                : _txt('—'),
          ),

          // Status
          SizedBox(width: AttendCols.status, child: _dotBadge(statusLabel, statusColor)),


        ],
      ),
    );
  }

  Widget _txt(String t, {Color? color, bool bold = false}) => Text(t,
      style: TextStyle(fontSize: 11,
          color: color ?? AppColors.textSecondary,
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal),
      overflow: TextOverflow.ellipsis);

  Widget _badge(String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
          overflow: TextOverflow.ellipsis));

  Widget _dotBadge(String label, Color color) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
            overflow: TextOverflow.ellipsis),
      ]);

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