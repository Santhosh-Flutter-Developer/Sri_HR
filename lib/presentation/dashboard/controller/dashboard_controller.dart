import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/data/models/dashboard_stats_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:sri_hr/data/utils/network_time.dart';
import 'package:sri_hr/presentation/attendance/repository/attendance_repository.dart';
import 'package:sri_hr/presentation/attendance/controller/shift_report_enricher.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/employee/repository/employee_repository.dart';
import 'package:sri_hr/presentation/leave/repository/leave_repository.dart';
import 'package:sri_hr/presentation/permission_request/repository/permission_request_repository.dart';

AuthController get auth => Get.find<AuthController>();

class DashboardController extends GetxController {
  final empRepo = EmployeeRepository();
  final attRepo = AttendanceRepository();
  final leaveRepo = LeaveRepository();
  final permRepo = PermissionRepository();
  final stats = Rxn<DashboardStats>();
  final isLoading = false.obs;

  // ── Date filter ──────────────────────────────────────────
  late final Rx<DateTime> selectedDate;
  final isCustomDate =
      false.obs; // true when user picked a date other than today

  @override
  void onInit() {
    super.onInit();
    selectedDate = NetworkTime.now().obs;
    loadStats();
  }

  // ── Pick a date via date picker ──────────────────────────
  Future<void> pickDate(BuildContext context) async {
    final now = NetworkTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF3B5BDB),
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      selectedDate.value = picked;
      final today = NetworkTime.now();
      isCustomDate.value =
          !(picked.year == today.year &&
              picked.month == today.month &&
              picked.day == today.day);
      await loadStats();
    }
  }

  // ── Reset to today ───────────────────────────────────────
  Future<void> resetToToday() async {
    selectedDate.value = NetworkTime.now();
    isCustomDate.value = false;
    await loadStats();
  }

  Future<void> loadStats() async {
    isLoading.value = true;
    try {
      await NetworkTime.syncTime();
      final companyId = auth.companyId;
      final date = selectedDate.value;
      final totalEmp = await empRepo.countEmployees(companyId);
      final presentCount = await attRepo.getPresentCount(companyId, date);
      final leaveCount = await leaveRepo.getLeaveCount(companyId, date);
      final pendingLeave = await leaveRepo.getPendingLeaveCount(companyId);
      final pendingPerm = await permRepo.getPendingPermissionCount(companyId);

      // Late entries for the selected date (first IN after shift start)
      int lateCount = 0;
      try {
        final dayLogs = await attRepo.getAttendanceLogs(companyId, date: date);
        lateCount = await ShiftReportEnricher.countLate(dayLogs, companyId);
      } catch (e) {
        log('Late count error: $e');
      }

      // Department wise employee count
      final deptRows = await SupabaseService.client
          .from('employees')
          .select('department_id, departments(name)')
          .eq('company_id', companyId)
          .eq('is_active', true);
      final Map<String, int> deptCounts = {};
      for (final row in deptRows) {
        final name = row['departments']?['name'] ?? 'Unknown';
        deptCounts[name] = (deptCounts[name] ?? 0) + 1;
      }

      stats.value = DashboardStats(
        totalEmployees: totalEmp,
        presentCount: presentCount,
        absentCount: (totalEmp - presentCount - leaveCount).clamp(0, totalEmp),
        leaveCount: leaveCount,
        permissionCount: 0,
        pendingLeaveCount: pendingLeave,
        pendingPermissionCount: pendingPerm,
        lateCount: lateCount,
        attendanceByDate: [],
        departmentWiseCount: deptCounts.entries
            .map((e) => {'name': e.key, 'count': e.value})
            .toList(),
      );
    } catch (e) {
      log("ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }
}