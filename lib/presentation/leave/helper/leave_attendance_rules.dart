// lib/presentation/leave/helper/leave_attendance_rules.dart
//
// Single place for the rules that tie LEAVE to ATTENDANCE.
//
// Applying leave:
//   1. Employee is currently punched IN (last punch of the day is "in")
//        -> blocked. Leave can only be applied before punch-in or after
//           punch-out.
//   2. Full-day leave on a date that already has punches
//        -> blocked (the employee has worked that day).
//      (For a range like 2.5 days, the half-day end dates are treated as
//       half days: first date = second half, last date = first half.)
//   3. Half-day leave on a date that already has punches
//        -> allowed only if the employee did NOT work the half being taken:
//             first half  : no IN punch before the half-day boundary
//             second half : no IN punch at/after the half-day boundary
//
// Half-day boundary = lunch start of the employee's shift (employee override,
// else company shift). If no lunch is configured it is the middle of the
// shift. If no shift is configured at all, rule 3 is skipped (rules 1 and 2
// still apply).
import 'package:sri_hr/data/models/attendance_log_model.dart';
import 'package:sri_hr/data/models/leave_request_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:sri_hr/presentation/company/repository/work_shift_repository.dart';

class LeaveAttendanceRules {
  /// Returns an error message if the leave must not be applied, else null.
  static Future<String?> validateLeaveAgainstPunches({
    required String companyId,
    required String employeeId,
    required String fromDate, // yyyy-MM-dd
    required String toDate, // yyyy-MM-dd
    required LeaveDayType dayType,
    bool startHalf = false,
    bool endHalf = false,
  }) async {
    final multiDay = fromDate != toDate;
    final rows = await SupabaseService.client
        .from('attendance_logs')
        .select('id, company_id, employee_id, date, punch_time, punch_type')
        .eq('company_id', companyId)
        .eq('employee_id', employeeId)
        .gte('date', fromDate)
        .lte('date', toDate)
        .order('punch_time', ascending: true);

    if ((rows as List).isEmpty) return null; // nobody punched → free to apply

    // Group punches per date (already chronological)
    final byDate = <String, List<AttendanceLogModel>>{};
    for (final r in rows) {
      final log = AttendanceLogModel.fromJson(r as Map<String, dynamic>);
      final ds = (r['date'] as String).substring(0, 10);
      byDate.putIfAbsent(ds, () => []).add(log);
    }

    int? boundary; // minutes from midnight; resolved lazily
    var boundaryLoaded = false;

    for (final entry in byDate.entries) {
      final ds = entry.key;
      final logs = entry.value;

      // What does THIS leave take on this particular date?
      // (last date of 2.5-day leave = first half only, etc.)
      final dateType = leaveDayTypeOn(
        fromDate: fromDate,
        toDate: toDate,
        dayType: dayType,
        startHalf: startHalf,
        endHalf: endHalf,
        date: ds,
      );

      // Rule 1 – currently punched in
      if (logs.last.punchType == PunchType.in_) {
        return 'Employee is currently punched in on ${_pretty(ds)}. '
            'Leave can only be applied before punch-in or after punch-out.';
      }

      // Rule 2 – full day after working
      if (!dateType.isHalf) {
        return 'Employee already has attendance on ${_pretty(ds)}. '
            'Full-day leave is not possible after working'
            '${multiDay ? ' — change the leave dates.' : ' — apply a Half Day leave instead.'}';
      }

      // Rule 3 – half day must not overlap the half already worked
      if (!boundaryLoaded) {
        boundary = await halfDayBoundaryMins(companyId, employeeId);
        boundaryLoaded = true;
      }
      if (boundary == null) continue; // no shift configured → can't compare

      final workedFirstHalf = logs.any(
        (l) => l.punchType == PunchType.in_ && _mins(l.punchTime) < boundary!,
      );
      final workedSecondHalf = logs.any(
        (l) => l.punchType == PunchType.in_ && _mins(l.punchTime) >= boundary!,
      );

      if (dateType == LeaveDayType.firstHalf && workedFirstHalf) {
        return 'Employee already worked the first half on ${_pretty(ds)}. '
            '${multiDay ? 'Change the leave dates.' : 'Choose Second Half instead.'}';
      }
      if (dateType == LeaveDayType.secondHalf && workedSecondHalf) {
        return 'Employee already worked the second half on ${_pretty(ds)}. '
            '${multiDay ? 'Change the leave dates.' : 'Choose First Half instead.'}';
      }
    }
    return null;
  }

  /// For a manual punch (admin adjust) on a date where the employee has an
  /// APPROVED half-day leave: is [punchTime] inside the leave half?
  static Future<bool> punchFallsInHalfDayLeave({
    required String companyId,
    required String employeeId,
    required LeaveDayType dayType,
    required DateTime punchTime,
  }) async {
    if (!dayType.isHalf) return true;
    final boundary = await halfDayBoundaryMins(companyId, employeeId);
    if (boundary == null) return false; // can't tell → don't block
    final m = _mins(punchTime);
    return dayType == LeaveDayType.firstHalf ? m < boundary : m >= boundary;
  }

  /// Minutes-from-midnight that separates first half from second half.
  static Future<int?> halfDayBoundaryMins(
    String companyId,
    String employeeId,
  ) async {
    String start = '', end = '', lunchStart = '';

    // Employee-level override first
    try {
      final emp = await SupabaseService.client
          .from('employees')
          .select('work_start_time, work_end_time, lunch_start_time')
          .eq('id', employeeId)
          .maybeSingle();
      start = _clean(emp?['work_start_time'] as String?);
      end = _clean(emp?['work_end_time'] as String?);
      lunchStart = _clean(emp?['lunch_start_time'] as String?);
    } catch (_) {}

    // Fall back to company shift
    if (start.isEmpty || end.isEmpty) {
      try {
        final shift = await WorkShiftRepository().getShift(companyId);
        if (shift != null) {
          start = _clean(shift.workStartTime);
          end = _clean(shift.workEndTime);
          lunchStart = _clean(shift.lunchStartTime);
        }
      } catch (_) {}
    }

    if (start.isEmpty || end.isEmpty) return null;
    if (lunchStart.isNotEmpty) return _toMins(lunchStart);

    final s = _toMins(start);
    var e = _toMins(end);
    if (e < s) e += 24 * 60; // overnight shift
    return (s + (e - s) ~/ 2) % (24 * 60);
  }

  // ── helpers ──────────────────────────────────────────────────────────────
  static int _mins(DateTime t) => t.hour * 60 + t.minute;

  static String _clean(String? t) {
    if (t == null || t.isEmpty) return '';
    final p = t.split(':');
    return p.length < 2 ? t : '${p[0]}:${p[1]}';
  }

  static int _toMins(String t) {
    final p = t.split(':');
    return (int.tryParse(p[0]) ?? 0) * 60 +
        (p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0);
  }

  static String _pretty(String ds) {
    final d = DateTime.tryParse(ds);
    if (d == null) return ds;
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${m[d.month - 1]} ${d.year}';
  }
}