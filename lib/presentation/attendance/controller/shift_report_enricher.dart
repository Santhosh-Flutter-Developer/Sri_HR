// lib/presentation/attendance/controller/shift_report_enricher.dart
//
// Enriches each attendance report row with:
//   shiftDisplay, expectedMins, lateMinutes,
//   permStatus, leaveStatus, presentOnLeave
//
// Usage:
//   final enriched = await ShiftReportEnricher.enrich(rows, companyId);
//
import 'package:sri_hr/data/models/employee_model.dart';
import 'package:sri_hr/data/models/work_shift_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:sri_hr/presentation/company/repository/work_shift_repository.dart';

class ShiftReportEnricher {
  // Cache shift per companyId so we only fetch once per enrich call
  static final Map<String, WorkShiftModel?> _shiftCache = {};

  /// Enrich rows in-place and return them.
  ///
  /// `rows` is the list from AttendanceController.groupedByEmployeeDate.
  /// Each row already has: employeeId, employee, date, inLogs, outLogs,
  ///   totalMins, isAbsent.
  ///
  /// After enrichment each row gains:
  ///   shiftDisplay (String?)
  ///   expectedMins (int?)
  ///   lateMinutes  (int?)
  ///   permStatus   (String?)   — "Approved" / "Pending" / "Rejected"
  ///   leaveStatus  (String?)   — "approved" / "pending" / "rejected"
  ///   presentOnLeave (bool)
  static Future<List<Map<String, dynamic>>> enrich(
    List<Map<String, dynamic>> rows,
    String companyId,
  ) async {
    _shiftCache.clear();

    // Pre-fetch shift once
    final shift = await _getShift(companyId);

    // Collect all (employeeId, date) combos for bulk leave/permission fetch
    final employeeIds = rows.map((r) => r['employeeId'] as String).toSet().toList();
    final dates = rows.map((r) {
      final d = r['date'] as DateTime;
      return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }).toSet().toList();

    // ── Bulk fetch approved leave_requests ────────────────────────────────
    // Returns rows with employee_id, from_date, to_date, status
    final leaveRows = employeeIds.isNotEmpty && dates.isNotEmpty
        ? await _fetchLeaves(companyId, employeeIds, dates)
        : <Map<String, dynamic>>[];

    // ── Bulk fetch permission_requests ────────────────────────────────────
    final permRows = employeeIds.isNotEmpty && dates.isNotEmpty
        ? await _fetchPermissions(companyId, employeeIds, dates)
        : <Map<String, dynamic>>[];

    // Build lookup maps
    // leave:      key = "${employeeId}_$dateStr"  → status string
    // permission: key = "${employeeId}_$dateStr"  → status string
    final Map<String, String> leaveMap       = {};
    final Map<String, String> permMap        = {};
    final Map<String, String> permTimingsMap = {};

    for (final r in leaveRows) {
      final empId = r['employee_id'] as String? ?? '';
      final from  = DateTime.tryParse(r['from_date'] as String? ?? '');
      final to    = DateTime.tryParse(r['to_date']   as String? ?? '');
      final status = r['status'] as String? ?? '';
      if (from == null || to == null) continue;
      // Mark every date in range
      DateTime cursor = DateTime(from.year, from.month, from.day);
      final end = DateTime(to.year, to.month, to.day);
      while (!cursor.isAfter(end)) {
        final ds = _ds(cursor);
        leaveMap['${empId}_$ds'] = status;
        cursor = cursor.add(const Duration(days: 1));
      }
    }

    for (final r in permRows) {
      final empId   = r['employee_id']  as String? ?? '';
      final dateStr = r['request_date'] as String? ?? '';
      final status  = r['status']       as String? ?? '';
      final fromT   = r['from_time']    as String? ?? '';
      final toT     = r['to_time']      as String? ?? '';
      permMap['${empId}_$dateStr'] = _capitalize(status);
      if (fromT.isNotEmpty && toT.isNotEmpty) {
        permTimingsMap['${empId}_$dateStr'] = '${_clean(fromT)}–${_clean(toT)}';
      }
    }

    // ── Enrich each row ────────────────────────────────────────────────────
    for (final row in rows) {
      final empId   = row['employeeId'] as String;
      final date    = row['date']       as DateTime;
      final dateStr = _ds(date);
      final key     = '${empId}_$dateStr';

      // Resolve the effective shift for this employee:
      // Use employee-level overrides when set, otherwise fall back to company shift.
      final employee = row['employee'] as EmployeeModel?;
      final empWorkStart  = _clean(employee?.workStartTime);
      final empWorkEnd    = _clean(employee?.workEndTime);
      final empLunchStart = _clean(employee?.lunchStartTime);
      final empLunchEnd   = _clean(employee?.lunchEndTime);

      final hasEmpShift = empWorkStart.isNotEmpty && empWorkEnd.isNotEmpty;

      final effectiveWorkStart  = hasEmpShift ? empWorkStart  : (shift != null ? _clean(shift.workStartTime)  : '');
      final effectiveWorkEnd    = hasEmpShift ? empWorkEnd    : (shift != null ? _clean(shift.workEndTime)    : '');
      final effectiveLunchStart = hasEmpShift ? empLunchStart : (shift != null ? _clean(shift.lunchStartTime ?? '') : '');
      final effectiveLunchEnd   = hasEmpShift ? empLunchEnd   : (shift != null ? _clean(shift.lunchEndTime   ?? '') : '');

      // Calculate expected work minutes for this employee
      final effectiveExpectedMins = _calcExpectedMins(
        effectiveWorkStart, effectiveWorkEnd,
        effectiveLunchStart, effectiveLunchEnd,
      );

      // Build a display string like "09:15 – 19:00"
      final effectiveShiftDisplay = (effectiveWorkStart.isNotEmpty && effectiveWorkEnd.isNotEmpty)
          ? '$effectiveWorkStart – $effectiveWorkEnd'
          : shift?.shiftDisplay;

      row['shiftDisplay'] = effectiveShiftDisplay;
      row['expectedMins'] = effectiveExpectedMins ?? shift?.expectedWorkMinutes;

      // Late arrival — compare first IN punch to effective shift start
      if (effectiveWorkStart.isNotEmpty) {
        final inLogs = row['inLogs'] as List;
        if (inLogs.isNotEmpty) {
          final firstIn = (inLogs.first).punchTime as DateTime;
          final shiftStartMins = _timeToMins(effectiveWorkStart);
          final actualStartMins = firstIn.hour * 60 + firstIn.minute;
          final late = actualStartMins - shiftStartMins;
          row['lateMinutes'] = late > 0 ? late : 0;
        } else {
          row['lateMinutes'] = null;
        }
      } else {
        row['lateMinutes'] = null;
      }

      // Leave
      final leaveStatus = leaveMap[key];
      row['leaveStatus']    = leaveStatus;

      // Present on Leave: employee has an approved leave but still punched
      final inLogs = row['inLogs'] as List;
      row['presentOnLeave'] = leaveStatus == 'approved' && inLogs.isNotEmpty;

      // Permission
      row['permStatus']  = permMap[key];
      row['permTimings'] = permTimingsMap[key];
    }

    return rows;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  static Future<WorkShiftModel?> _getShift(String companyId) async {
    if (_shiftCache.containsKey(companyId)) return _shiftCache[companyId];
    final s = await WorkShiftRepository().getShift(companyId);
    _shiftCache[companyId] = s;
    return s;
  }

  static Future<List<Map<String, dynamic>>> _fetchLeaves(
    String companyId,
    List<String> employeeIds,
    List<String> dates,
  ) async {
    try {
      final rows = await SupabaseService.client
          .from('leave_requests')
          .select('employee_id, from_date, to_date, status')
          .eq('company_id', companyId)
          .inFilter('employee_id', employeeIds)
          .inFilter('status', ['approved', 'pending', 'rejected']);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchPermissions(
    String companyId,
    List<String> employeeIds,
    List<String> dates,
  ) async {
    try {
      final rows = await SupabaseService.client
          .from('permission_requests')
          .select('employee_id, request_date, status, from_time, to_time')
          .eq('company_id', companyId)
          .inFilter('employee_id', employeeIds)
          .inFilter('request_date', dates);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (_) {
      return [];
    }
  }

  static String _ds(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Strips seconds from DB time strings: "09:15:00" → "09:15"
  static String _clean(String? t) {
    if (t == null || t.isEmpty) return '';
    final parts = t.split(':');
    if (parts.length < 2) return t;
    return '${parts[0]}:${parts[1]}';
  }

  // Calculates net work minutes (work duration minus lunch break)
  static int? _calcExpectedMins(
    String workStart, String workEnd,
    String lunchStart, String lunchEnd,
  ) {
    if (workStart.isEmpty || workEnd.isEmpty) return null;
    int total = _timeToMins(workEnd) - _timeToMins(workStart);
    if (total < 0) total += 24 * 60; // overnight shift
    if (lunchStart.isNotEmpty && lunchEnd.isNotEmpty) {
      final lunchMins = _timeToMins(lunchEnd) - _timeToMins(lunchStart);
      if (lunchMins > 0) total -= lunchMins;
    }
    return total;
  }

  static int _timeToMins(String t) {
    final p = t.split(':');
    if (p.length < 2) return 0;
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}