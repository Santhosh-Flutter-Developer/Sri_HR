import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/handler/exception_handler.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/attendance_log_model.dart';
import 'package:sri_hr/data/models/employee_model.dart';
import 'package:sri_hr/data/services/attendance_export_service.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:sri_hr/data/utils/network_time.dart';
import 'package:sri_hr/presentation/attendance/repository/attendance_repository.dart';
import 'package:sri_hr/presentation/attendance/widgets/export_format_dialog.dart';
import 'package:sri_hr/presentation/attendance/widgets/filter_sheet.dart';
import 'package:sri_hr/presentation/attendance/widgets/punch_form_dialog.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/data/helper/helper.dart';
import 'package:sri_hr/data/services/connectivity_service.dart';
import 'package:sri_hr/presentation/attendance/controller/shift_report_enricher.dart';

AuthController get auth => Get.find<AuthController>();

class AttendanceController extends GetxController {
  final repo = AttendanceRepository();
  final logs = <AttendanceLogModel>[].obs;
  final allEmployees = <EmployeeModel>[].obs;
  final isLoading = false.obs;
  // Shift-enriched rows (built after groupedByEmployeeDate is ready)
  final enrichedRows = <Map<String, dynamic>>[].obs;
  // Filters
  final fromDate = Rxn<DateTime>();
  final toDate = Rxn<DateTime>();
  final RxBool showErr = true.obs;
  final filterEmployeeId = RxnString();
  final filterDepartmentId = RxnString();
  final activePreset = RxnString();
  // 'present' | 'absent' | 'leave' | null
  final statusFilter = RxnString();

  void toggleStatusFilter(String status) {
    statusFilter.value = statusFilter.value == status ? null : status;
    currentPage.value = 0;
  }

  // View mode: 'table' or 'grid'
  final viewMode = 'table'.obs;

  // Pagination
  final pageSize = 10.obs;
  final currentPage = 0.obs;
  final pageSizeOptions = [10, 20, 50, 100];

  // ── Punch Adjustment filters (independent from attendance report) ──────────
  final punchFromDate = Rxn<DateTime>();
  final punchToDate = Rxn<DateTime>();
  final punchFilterEmployeeId = RxnString();
  final punchActivePreset = RxnString();
  // Punch-specific pagination
  final punchPageSize = 10.obs;
  final punchCurrentPage = 0.obs;
  // Punch logs loaded separately
  final punchLogs = <AttendanceLogModel>[].obs;
  final isPunchLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _registerReload();
    NetworkTime.syncTime();

    final args = Get.arguments;
    DateTime initialDate = NetworkTime.now();
    String? initialStatus;
    bool fromDashboard = false;

    if (args is Map) {
      final argDate = args['date'];
      if (argDate is DateTime) {
        initialDate = argDate;
        fromDashboard = true;
      }
      final argStatus = args['statusFilter'];
      if (argStatus is String) {
        initialStatus = argStatus;
      }
    }

    fromDate.value = initialDate;
    toDate.value = initialDate;
    final now = NetworkTime.now();
    final isToday =
        initialDate.year == now.year &&
        initialDate.month == now.month &&
        initialDate.day == now.day;
    activePreset.value = (!fromDashboard || isToday) ? 'today' : null;
    statusFilter.value = initialStatus;

    // Punch adjustment defaults to today
    punchFromDate.value = now;
    punchToDate.value = now;
    punchActivePreset.value = 'today';

    loadLogs();
    loadPunchLogs();
  }

  void _registerReload() {
    try {
      Get.find<ConnectivityService>().register(loadLogs);
    } catch (_) {}
  }

  Future<void> loadLogs() async {
    if (auth.companyId.isEmpty) {
      logs.value = [];
      allEmployees.value = [];
      return;
    }
    isLoading.value = true;
    currentPage.value = 0;
    try {
      final results = await Future.wait([
        repo.getAttendanceLogs(
          auth.companyId,
          fromDate: fromDate.value,
          toDate: toDate.value,
          employeeId: !auth.isAdmin ? auth.employeeId : filterEmployeeId.value,
        ),
        if (auth.isAdmin)
          repo.getActiveEmployees(
            auth.companyId,
            departmentId: filterDepartmentId.value,
          )
        else if (auth.employeeId != null)
          repo.getActiveEmployees(auth.companyId),
      ]);
      logs.value = results[0] as List<AttendanceLogModel>;
      if (auth.isAdmin) {
        allEmployees.value = results[1] as List<EmployeeModel>;
      } else if (auth.employeeId != null && results.length > 1) {
        // Store just own record so absent-row injection has employee object
        final all = results[1] as List<EmployeeModel>;
        allEmployees.value = all.where((e) => e.id == auth.employeeId).toList();
      }
      // ── Enrich rows with shift / leave / permission data ─────────────────
      final baseRows = List<Map<String, dynamic>>.from(groupedByEmployeeDate);
      enrichedRows.value = await ShiftReportEnricher.enrich(
        baseRows,
        auth.companyId,
      );
    } catch (e) {
      debugPrint('[AttendCtrl] load error: $e');
      showError(handleException(e));
    } finally {
      isLoading.value = false;
    }
  }

  // ── Punch Adjustment data loading ──────────────────────────────────────────

  Future<void> loadPunchLogs() async {
    if (auth.companyId.isEmpty) {
      punchLogs.value = [];
      return;
    }
    isPunchLoading.value = true;
    punchCurrentPage.value = 0;
    try {
      final fetched = await repo.getAttendanceLogs(
        auth.companyId,
        fromDate: punchFromDate.value,
        toDate: punchToDate.value,
        employeeId: !auth.isAdmin
            ? auth.employeeId
            : punchFilterEmployeeId.value,
      );
      // Keep only manual logs
      punchLogs.value = fetched.where((l) => l.isManual).toList();
    } catch (e) {
      debugPrint('[PunchCtrl] load error: $e');
      showError(handleException(e));
    } finally {
      isPunchLoading.value = false;
    }
  }

  void applyPunchFilters({
    DateTime? from,
    DateTime? to,
    String? employeeId,
    String? preset,
  }) {
    if (from != null) punchFromDate.value = from;
    if (to != null) punchToDate.value = to;
    if (employeeId != null) {
      punchFilterEmployeeId.value = employeeId == '' ? null : employeeId;
    }
    punchActivePreset.value = preset;
    punchCurrentPage.value = 0;
    loadPunchLogs();
  }

  void clearPunchFilters() {
    final now = NetworkTime.now();
    punchFromDate.value = now;
    punchToDate.value = now;
    punchFilterEmployeeId.value = null;
    punchActivePreset.value = 'today';
    punchCurrentPage.value = 0;
    loadPunchLogs();
  }

  /// Grouped manual-only rows for punch adjustment
  List<Map<String, dynamic>> get groupedPunchRows {
    final Map<String, Map<String, dynamic>> grouped = {};
    for (final log in punchLogs) {
      final key =
          '${log.employeeId}_${log.date.toIso8601String().substring(0, 10)}';
      grouped.putIfAbsent(
        key,
        () => {
          'employeeId': log.employeeId,
          'employee': log.employee,
          'date': log.date,
          'inLogs': <AttendanceLogModel>[],
          'outLogs': <AttendanceLogModel>[],
          'totalMins': 0,
        },
      );
      if (log.punchType == PunchType.in_) {
        (grouped[key]!['inLogs'] as List<AttendanceLogModel>).add(log);
      } else {
        (grouped[key]!['outLogs'] as List<AttendanceLogModel>).add(log);
      }
    }
    for (final row in grouped.values) {
      final ins = (row['inLogs'] as List<AttendanceLogModel>)
        ..sort((a, b) => a.punchTime.compareTo(b.punchTime));
      final outs = (row['outLogs'] as List<AttendanceLogModel>)
        ..sort((a, b) => a.punchTime.compareTo(b.punchTime));
      int totalMins = 0;
      final pairs = ins.length < outs.length ? ins.length : outs.length;
      for (int i = 0; i < pairs; i++) {
        totalMins += outs[i].punchTime.difference(ins[i].punchTime).inMinutes;
      }
      row['totalMins'] = totalMins;
    }
    final list = grouped.values.toList();
    list.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );
    return list;
  }

  List<Map<String, dynamic>> get pagedPunchRows {
    final all = groupedPunchRows;
    final start = punchCurrentPage.value * punchPageSize.value;
    if (start >= all.length) return [];
    final end = (start + punchPageSize.value).clamp(0, all.length);
    return all.sublist(start, end);
  }

  int get totalPunchPages {
    final total = groupedPunchRows.length;
    if (total == 0) return 1;
    return (total / punchPageSize.value).ceil();
  }

  void goToPunchPage(int page) {
    punchCurrentPage.value = page.clamp(0, totalPunchPages - 1);
  }

  void setPunchPageSize(int size) {
    punchPageSize.value = size;
    punchCurrentPage.value = 0;
  }

  void applyFilters({
    DateTime? from,
    DateTime? to,
    String? employeeId,
    String? departmentId,
    String? preset,
  }) {
    if (from != null) fromDate.value = from;
    if (to != null) toDate.value = to;
    if (employeeId != null) {
      filterEmployeeId.value = employeeId == '' ? null : employeeId;
    }
    if (departmentId != null) {
      filterDepartmentId.value = departmentId == '' ? null : departmentId;
    }
    activePreset.value = preset;
    currentPage.value = 0;
    loadLogs();
  }

  void clearFilters() {
    final now = NetworkTime.now();
    fromDate.value = now;
    toDate.value = now;
    filterEmployeeId.value = null;
    filterDepartmentId.value = null;
    activePreset.value = 'today';
    currentPage.value = 0;
    loadLogs();
  }

  /// Group logs by employee+date — includes absent employees too.
  /// All active employees appear for every date in the range.
  List<Map<String, dynamic>> get groupedByEmployeeDate {
    final Map<String, Map<String, dynamic>> map = {};

    // Step 1: add rows for employees who punched in/out
    for (final log in logs) {
      final dateStr = log.date.toIso8601String().substring(0, 10);
      final key = '${log.employeeId}_$dateStr';
      map.putIfAbsent(
        key,
        () => {
          'employeeId': log.employeeId,
          'employee': log.employee,
          'date': log.date,
          'inLogs': <AttendanceLogModel>[],
          'outLogs': <AttendanceLogModel>[],
          'totalMins': 0,
          'isAbsent': false,
        },
      );
      if (log.punchType == PunchType.in_) {
        (map[key]!['inLogs'] as List).add(log);
      } else {
        (map[key]!['outLogs'] as List).add(log);
      }
    }

    // Step 2: calculate totals
    for (final row in map.values) {
      final ins = (row['inLogs'] as List<AttendanceLogModel>)
        ..sort((a, b) => a.punchTime.compareTo(b.punchTime));
      final outs = (row['outLogs'] as List<AttendanceLogModel>)
        ..sort((a, b) => a.punchTime.compareTo(b.punchTime));
      int totalMins = 0;
      final pairs = ins.length < outs.length ? ins.length : outs.length;
      for (int i = 0; i < pairs; i++) {
        totalMins += outs[i].punchTime.difference(ins[i].punchTime).inMinutes;
      }
      row['totalMins'] = totalMins;
    }

    // Step 3: inject absent rows
    final from = fromDate.value;
    final to = toDate.value;
    if (from != null && to != null) {
      final presentKeys = map.keys.toSet();
      DateTime cursor = DateTime(from.year, from.month, from.day);
      final end = DateTime(to.year, to.month, to.day);

      if (auth.isAdmin && allEmployees.isNotEmpty) {
        // Admin: inject for every active employee on every date
        while (!cursor.isAfter(end)) {
          final dateStr = cursor.toIso8601String().substring(0, 10);
          final dateCopy = cursor;
          for (final emp in allEmployees) {
            if (filterEmployeeId.value != null &&
                filterEmployeeId.value!.isNotEmpty &&
                emp.id != filterEmployeeId.value) {
              continue;
            }
            final key = '${emp.id}_$dateStr';
            if (!presentKeys.contains(key)) {
              map[key] = {
                'employeeId': emp.id,
                'employee': emp,
                'date': dateCopy,
                'inLogs': <AttendanceLogModel>[],
                'outLogs': <AttendanceLogModel>[],
                'totalMins': 0,
                'isAbsent': true,
              };
            }
          }
          cursor = cursor.add(const Duration(days: 1));
        }
      } else if (!auth.isAdmin && auth.employeeId != null) {
        // Regular user: inject absent rows for every date they didn't punch
        final existingEmp = allEmployees.isNotEmpty
            ? allEmployees.first
            : (map.values.isNotEmpty ? map.values.first['employee'] : null);
        while (!cursor.isAfter(end)) {
          final dateStr = cursor.toIso8601String().substring(0, 10);
          final dateCopy = cursor;
          final key = '${auth.employeeId}_$dateStr';
          if (!presentKeys.contains(key)) {
            map[key] = {
              'employeeId': auth.employeeId,
              'employee': existingEmp,
              'date': dateCopy,
              'inLogs': <AttendanceLogModel>[],
              'outLogs': <AttendanceLogModel>[],
              'totalMins': 0,
              'isAbsent': true,
            };
          }
          cursor = cursor.add(const Duration(days: 1));
        }
      }
    }

    // Step 4: sort by date desc, then employee name
    final list = map.values.toList();
    list.sort((a, b) {
      final dateCmp = (b['date'] as DateTime).compareTo(a['date'] as DateTime);
      if (dateCmp != 0) return dateCmp;
      final aName = (a['employee'] as dynamic)?.fullName as String? ?? '';
      final bName = (b['employee'] as dynamic)?.fullName as String? ?? '';
      return aName.compareTo(bName);
    });
    return list;
  }

  /// True when from and to are the same calendar day
  bool get isSingleDay {
    final f = fromDate.value;
    final t = toDate.value;
    if (f == null || t == null) return false;
    return f.year == t.year && f.month == t.month && f.day == t.day;
  }

  /// Unique employees who have at least one IN punch
  int get presentCount {
    return logs
        .where((l) => l.punchType == PunchType.in_)
        .map((l) => l.employeeId)
        .toSet()
        .length;
  }

  /// Active employees minus present minus on-leave (admin only)
  int get absentCount {
    if (!auth.isAdmin) return 0;
    return (allEmployees.length - presentCount - leaveCount).clamp(
      0,
      allEmployees.length,
    );
  }

  /// Employees on approved leave (from enriched rows, single-day view)
  int get leaveCount {
    return enrichedRows.where((r) => r['leaveStatus'] == 'approved').length;
  }

  /// Rows after applying the present/absent/leave status filter
  List<Map<String, dynamic>> get filteredRows {
    final rows = groupedByEmployeeDate;
    if (!isSingleDay || statusFilter.value == null) return rows;
    if (statusFilter.value == 'leave') {
      // Leave filter driven by enrichedRows; return unfiltered here as fallback
      return rows;
    }
    if (statusFilter.value == 'absent') {
      // Absent = no punch AND not on approved leave
      return rows.where((r) => (r['isAbsent'] as bool) == true).toList();
    }
    // Present = has punches
    return rows.where((r) => (r['isAbsent'] as bool) == false).toList();
  }

  /// Enriched rows after applying the present/absent/leave status filter
  List<Map<String, dynamic>> get filteredEnrichedRows {
    final rows = enrichedRows;
    if (!isSingleDay || statusFilter.value == null) return rows;
    if (statusFilter.value == 'leave') {
      // Leave = approved leave (regardless of punch)
      return rows.where((r) => r['leaveStatus'] == 'approved').toList();
    }
    if (statusFilter.value == 'absent') {
      // Absent = no punch AND not on approved leave
      return rows
          .where(
            (r) =>
                (r['isAbsent'] as bool) == true &&
                r['leaveStatus'] != 'approved',
          )
          .toList();
    }
    // Present = has punches
    return rows.where((r) => (r['isAbsent'] as bool) == false).toList();
  }

  /// Current page slice (uses enriched rows)
  List<Map<String, dynamic>> get pagedRows {
    final all = filteredEnrichedRows.isNotEmpty
        ? filteredEnrichedRows
        : filteredRows;
    final start = currentPage.value * pageSize.value;
    if (start >= all.length) return [];
    final end = (start + pageSize.value).clamp(0, all.length);
    return all.sublist(start, end);
  }

  int get totalPages {
    final total = filteredEnrichedRows.isNotEmpty
        ? filteredEnrichedRows.length
        : filteredRows.length;
    if (total == 0) return 1;
    return (total / pageSize.value).ceil();
  }

  void goToPage(int page) {
    currentPage.value = page.clamp(0, totalPages - 1);
  }

  void setPageSize(int size) {
    pageSize.value = size;
    currentPage.value = 0;
  }

  Future<void> loadLogsRange(DateTime from, DateTime to) async {
    isLoading.value = true;
    try {
      logs.value = await repo.getAttendanceLogs(
        auth.companyId,
        fromDate: from,
        toDate: to,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<AttendanceLogModel?> getTodayAttendance(String id) async {
    final todayAtt = await repo.getTodayAttendance(id);
    return todayAtt;
  }

  Future<void> adjustPunch(
    Map<String, dynamic> data, {
    bool showToast = true,
    bool isManual = true,
  }) async {
    try {
      if (auth.companyId.isNotEmpty) {
        data['company_id'] = auth.companyId;
      }
      if (auth.userId.isNotEmpty) {
        data['adjusted_by'] = auth.userId;
      } else {
        data.remove('adjusted_by');
      }
      final companyId = data['company_id'] as String;
      final empId = data['employee_id'] as String;
      final dateStr = data['date'] as String;
      final punchType = data['punch_type'] as String;
      final newPunchTime = DateTime.parse(data['punch_time'] as String);

      // ── NEW: Check if employee is on approved leave this date ──
      final leaveCheck = await SupabaseService.client
          .from('leave_requests')
          .select('id, from_date, to_date')
          .eq('company_id', companyId)
          .eq('employee_id', empId)
          .eq('status', 'approved')
          .lte('from_date', dateStr)
          .gte('to_date', dateStr)
          .maybeSingle();

      if (leaveCheck != null) {
        showError(
          'Cannot add punch on $dateStr — employee has an approved leave on this date',
        );
        showErr.value = false;
        return;
      }

      final freshLogs = await repo.getAttendanceLogs(
        companyId,
        date: newPunchTime,
        employeeId: empId,
      );

      // ... rest of existing validation (sequence check, time check) ...
      final sameDayLogs =
          freshLogs
              .where(
                (l) =>
                    l.employeeId == empId &&
                    l.date.toIso8601String().substring(0, 10) == dateStr,
              )
              .toList()
            ..sort((a, b) => a.punchTime.compareTo(b.punchTime));

      final inLogs = sameDayLogs
          .where((l) => l.punchType == PunchType.in_)
          .toList();
      final outLogs = sameDayLogs
          .where((l) => l.punchType == PunchType.out)
          .toList();

      // ✅ Check actual last punch type, not counts
      final lastLog = sameDayLogs.isNotEmpty ? sameDayLogs.last : null;
      if (punchType == 'out') {
        // Can only punch out if last punch was "in"
        if (lastLog == null || lastLog.punchType != PunchType.in_) {
          showError(
            'Punch IN must be recorded before Punch OUT. Please add an IN record first.',
          );
          showErr.value = false;
          return;
        }
      }

      if (punchType == 'in') {
        // Can only punch in if no punch yet, or last punch was "out"
        if (lastLog != null && lastLog.punchType == PunchType.in_) {
          showError(
            'Please record a Punch OUT before adding another Punch IN.',
          );
          showErr.value = false;
          return;
        }
      }

      if (sameDayLogs.isNotEmpty) {
        final lastPunchTime = sameDayLogs.last.punchTime;
        final newMinutes = newPunchTime.hour * 60 + newPunchTime.minute;
        final lastMinutes = lastPunchTime.hour * 60 + lastPunchTime.minute;
        if (newMinutes <= lastMinutes) {
          showError(
            'Time must be after ${AttendanceController.fmtTime(lastPunchTime)}',
          );
          showErr.value = false;
          return;
        }
      }
      showErr.value = true;
      final log = await repo.adjustPunch(data, isManual: isManual);
      logs.add(log);
      if (isManual) punchLogs.add(log);
      if (showToast == true) showSuccess('Punch adjusted successfully');
    } catch (e) {
      debugPrint('[AdjustPunch] error: $e');
      showError(handleException(e));
    }
  }

  String fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void confirmDelete(BuildContext context, String id) {
    // log(
    //   "ABuddy:${a?.employee?.fullName}-(${fmtDate(a!.date)}-${fmtTime(a.punchTime)})",
    // );
    showDialog(
      context: context,
      builder: (_) {
        var rec = logs.firstWhereOrNull((l) => l.id == id);
        return AlertDialog(
          insetPadding: EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delete Report'),
          content: Text(
            'Are you sure you want to delete this record ${rec?.employee?.fullName} - (${fmtDate(rec!.date)} - ${fmtTime(rec.punchTime)})?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                deleteLog(id);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteLog(String id) async {
    try {
      await repo.deleteLog(id);
      logs.removeWhere((l) => l.id == id);
      punchLogs.removeWhere((l) => l.id == id);
      loadLogs();
      loadPunchLogs();
      showSuccess('Log deleted');
    } catch (e) {
      showError(handleException(e));
    }
  }

  String formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Future<void> showExportMenu(BuildContext context) async {
    // ✅ AFTER — same enriched + filtered rows the table displays
    final rows = filteredEnrichedRows.isNotEmpty
        ? filteredEnrichedRows
        : filteredRows;
    if (rows.isEmpty) {
      showWarning('No attendance data to export for the selected period.');
      return;
    }

    final format = await showDialog<ExportFormat>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ExportFormatDialog(),
    );

    if (format == null || !context.mounted) return;

    final companyName = 'Attendance Report';
    final from = fromDate.value ?? DateTime.now();
    final to = toDate.value ?? DateTime.now();

    try {
      if (format == ExportFormat.pdf) {
        showSuccess('Generating PDF…');
        await AttendanceExportService.exportPDF(
          context: context,
          rows: rows,
          fromDate: from,
          toDate: to,
          companyName: companyName,
        );
      } else {
        showSuccess('Generating Excel…');
        await AttendanceExportService.exportExcel(
          context: context,
          rows: rows,
          fromDate: from,
          toDate: to,
          companyName: companyName,
        );
      }
    } catch (e) {
      debugPrint('[Export] error: $e');
      if (context.mounted) {
        showError(handleException(e));
      }
    }
  }

  void showForm(
    BuildContext context,
    AttendanceController controller, {
    Map<String, dynamic>? prefillRow,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          PunchFormDialog(controller: controller, prefillRow: prefillRow),
    );
  }

  void showFilterSheet(BuildContext context, AttendanceController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(controller: controller),
    );
  }

  void exportCSV(BuildContext context, AttendanceController controller) {
    final rows = controller.groupedByEmployeeDate;
    if (rows.isEmpty) {
      showWarning('No attendance data to export for the selected period.');
      return;
    }
    final buf = StringBuffer();
    buf.writeln(
      'Employee Code,Employee Name,Date,IN Time,OUT Time,Total Hours,Manual',
    );
    for (final row in rows) {
      final emp = row['employee'] as dynamic;
      final date = row['date'] as DateTime;
      final inLogs = row['inLogs'] as List<AttendanceLogModel>;
      final outLogs = row['outLogs'] as List<AttendanceLogModel>;
      final totalMins = row['totalMins'] as int;
      final code = emp?.employeeCode as String? ?? '';
      final name = emp?.fullName as String? ?? '';
      final dateStr =
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/${date.year}';
      final inStr = inLogs.isNotEmpty ? fmtTime(inLogs.first.punchTime) : '';
      final outStr = outLogs.isNotEmpty ? fmtTime(outLogs.last.punchTime) : '';
      final hrs = totalMins > 0
          ? '${totalMins ~/ 60}.${(totalMins % 60 * 100 ~/ 60).toString().padLeft(2, '0')}'
          : '';
      final isManual = (inLogs + outLogs).any((l) => l.isManual) ? 'Yes' : 'No';
      buf.writeln(
        '"$code","$name","$dateStr","$inStr","$outStr","$hrs","$isManual"',
      );
    }

    // Download/show CSV
    if (kIsWeb) {
      // Web: trigger download via anchor
      final bytes = utf8.encode(buf.toString());
      final blob = base64.encode(bytes);
      debugPrint('[Export] CSV data prepared (${bytes.length} bytes)');
      // Show preview snackbar
      showSuccess('Exported \${rows.length} records. CSV ready.');
    } else {
      showSuccess('Exported \${rows.length} records');
    }
    debugPrint('[Export] CSV:\n$buf');
  }

  static String fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
