import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/attendance_log_model.dart';
import 'package:sri_hr/presentation/attendance/repository/attendance_repository.dart';
import 'package:sri_hr/presentation/attendance/ui/punch_form_dialog.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/helper/helper.dart';
import 'package:sri_hr/presentation/leave/repository/leave_repository.dart';

AuthController get auth => Get.find<AuthController>();

class AttendanceController extends GetxController {
  final repo = AttendanceRepository();
  final leaveRepo = LeaveRepository();
  final logs = <AttendanceLogModel>[].obs;
  final isLoading = false.obs;
  final selectedDate = DateTime.now().obs;
  final filterDepartmentId = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadLogs();
  }

  Future<void> loadLogs() async {
    try {
      isLoading.value = true;
      logs.value = await repo.getAttendanceLogs(
        auth.companyId,
        date: selectedDate.value,
      );
    } catch (e) {
      showError('Failed to load attendance logs');
    } finally {
      isLoading.value = false;
    }
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

  // Compute summary per employee for the attendance report
  Map<String, Map<String, dynamic>> computeSummary() {
    final Map<String, Map<String, dynamic>> result = {};
    for (final log in logs) {
      final empId = log.employeeId;
      result.putIfAbsent(
        empId,
        () => {'employee': log.employee, 'logs': <AttendanceLogModel>[]},
      );
      (result[empId]!['logs'] as List).add(log);
    }
    // Calculate working hours per employee per date
    for (final entry in result.entries) {
      final empLogs = (entry.value['logs'] as List<AttendanceLogModel>);
      empLogs.sort((a, b) => a.punchTime.compareTo(b.punchTime));
      double totalHours = 0;
      for (int i = 0; i < empLogs.length - 1; i++) {
        if (empLogs[i].punchType == PunchType.in_ &&
            empLogs[i + 1].punchType == PunchType.out) {
          totalHours +=
              empLogs[i + 1].punchTime
                  .difference(empLogs[i].punchTime)
                  .inMinutes /
              60.0;
        }
      }
      entry.value['total_hours'] = totalHours;
    }
    return result;
  }

  Future<void> adjustPunch(Map<String, dynamic> data) async {
    try {
      data['company_id'] = auth.companyId;
      data['adjusted_by'] = auth.userId;
      data['is_manual'] = true;
      final log = await repo.adjustPunch(data);
      logs.add(log);
      showSuccess('Punch adjusted successfully');
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
      showError('$e');
    }
  }

  Future<void> pickDate(
    BuildContext context,
    AttendanceController controller,
  ) async {
    final d = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      controller.selectedDate.value = d;
      controller.loadLogs();
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
    AttendanceController ctrl, {
    Map<String, dynamic>? prefillRow,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PunchFormDialog(controller: ctrl, prefillRow: prefillRow),
    );
  }
}
