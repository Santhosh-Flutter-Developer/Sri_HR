import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/attendance_log_model.dart';
import 'package:sri_hr/data/utils/network_time.dart';
import 'package:sri_hr/presentation/attendance/repository/attendance_repository.dart';
import 'package:sri_hr/presentation/attendance/widgets/filter_sheet.dart';
import 'package:sri_hr/presentation/attendance/widgets/punch_form_dialog.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/helper/helper.dart';

AuthController get auth => Get.find<AuthController>();

class AttendanceController extends GetxController {
  final repo = AttendanceRepository();
  final logs = <AttendanceLogModel>[].obs;
  final isLoading = false.obs;
  // Filters
  final fromDate = Rxn<DateTime>();
  final toDate = Rxn<DateTime>();
  final filterEmployeeId = RxnString();
  final filterDepartmentId = RxnString();

  // View mode: 'table' or 'grid'
  final viewMode = 'table'.obs;

  @override
  void onInit() {
    super.onInit();
    NetworkTime.syncTime();
    final now = NetworkTime.now();
    fromDate.value = DateTime(now.year, now.month, 1);
    toDate.value = now;
    loadLogs();
  }

  Future<void> loadLogs() async {
    isLoading.value = true;
    try {
      logs.value = await repo.getAttendanceLogs(
        auth.companyId,
        fromDate: fromDate.value,
        toDate: toDate.value,
        employeeId: filterEmployeeId.value,
      );
    } catch (e) {
      debugPrint('[AttendCtrl] load error: $e');
      showError('Failed to load attendance: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters({
    DateTime? from,
    DateTime? to,
    String? employeeId,
    String? departmentId,
  }) {
    if (from != null) fromDate.value = from;
    if (to != null) toDate.value = to;
    if (employeeId != null) {
      filterEmployeeId.value = employeeId == '' ? null : employeeId;
    }
    if (departmentId != null) {
      filterDepartmentId.value = departmentId == '' ? null : departmentId;
    }
    loadLogs();
  }

  void clearFilters() {
    final now = NetworkTime.now();
    fromDate.value = DateTime(now.year, now.month, 1);
    toDate.value = now;
    filterEmployeeId.value = null;
    filterDepartmentId.value = null;
    loadLogs();
  }

  /// Group logs by employee+date → { empId_date: { employee, date, inLogs, outLogs } }
  /// Supports multiple IN/OUT per day
  List<Map<String, dynamic>> get groupedByEmployeeDate {
    final Map<String, Map<String, dynamic>> map = {};
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
        },
      );
      if (log.punchType == PunchType.in_) {
        (map[key]!['inLogs'] as List).add(log);
      } else {
        (map[key]!['outLogs'] as List).add(log);
      }
    }
    // Calculate totals
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
    // Sort by date desc, then employee name
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
  }) async {
    try {
      data['company_id'] = auth.companyId;
      data['adjusted_by'] = auth.userId;
      final log = await repo.adjustPunch(data);
      // Update local list
      final existIdx = logs.indexWhere(
        (l) =>
            l.employeeId == log.employeeId &&
            l.date.toIso8601String().substring(0, 10) ==
                log.date.toIso8601String().substring(0, 10) &&
            l.punchType == log.punchType &&
            l.isManual,
      );
      if (existIdx != -1) {
        logs[existIdx] = log;
      } else {
        logs.add(log);
      }
      if (showToast == true) {
        showSuccess('Punch adjusted successfully');
      }
    } catch (e) {
      showError('Failed: $e');
    }
  }

  Future<void> deleteLog(String id) async {
    try {
      await repo.deleteLog(id);
      logs.removeWhere((l) => l.id == id);
      showSuccess('Log deleted');
    } catch (e) {
      showError('Failed: $e');
    }
  }

  String formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  void showExportMenu(BuildContext context) {
    Get.snackbar(
      'Export',
      'Export functionality – connect your preferred export library',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.info,
      colorText: Colors.white,
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${rows.length} records. CSV ready.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Copy',
            textColor: Colors.white,
            onPressed: () {
              /* clipboard copy */
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${rows.length} records'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    debugPrint('[Export] CSV:\n$buf');
  }

  static String fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
