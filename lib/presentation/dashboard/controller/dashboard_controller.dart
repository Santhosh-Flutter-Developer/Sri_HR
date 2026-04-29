import 'dart:developer';

import 'package:get/get.dart';
import 'package:sri_hr/data/models/dashboard_stats_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:sri_hr/presentation/attendance/repository/attendance_repository.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/employee/repository/employee_repository.dart';
import 'package:sri_hr/presentation/leave/repository/leave_repository.dart';

AuthController get auth => Get.find<AuthController>();

class DashboardController extends GetxController {
  final empRepo = EmployeeRepository();
  final attRepo = AttendanceRepository();
  final leaveRepo = LeaveRepository();
  final stats = Rxn<DashboardStats>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadStats();
  }

  Future<void> loadStats() async {
    isLoading.value = true;
    try {
      final companyId = auth.companyId;
      final today = DateTime.now();
      final totalEmp = await empRepo.countEmployees(companyId);
      final presentCount = await attRepo.getPresentCount(companyId, today);
      final leaveCount = await leaveRepo.getLeaveCount(companyId, today);

      //Department wise employee count
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
        absentCount: totalEmp - presentCount - leaveCount,
        leaveCount: leaveCount,
        permissionCount: 0,
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
