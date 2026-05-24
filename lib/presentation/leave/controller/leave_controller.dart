import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/leave_request_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/helper/helper.dart';
import 'package:sri_hr/presentation/leave/repository/leave_repository.dart';
import 'package:sri_hr/presentation/leave/ui/leave_form_dialog.dart';

AuthController get auth => Get.find<AuthController>();

class LeaveController extends GetxController {
  final _repo = LeaveRepository();
  final leaves = <LeaveRequestModel>[].obs;
  final isLoading = false.obs;
  final filterStatus = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadLeaves();
  }

  List<LeaveRequestModel> get filteredLeaves {
    if (filterStatus.value == null) return leaves;
    return leaves.where((l) => l.status.name == filterStatus.value).toList();
  }

  Future<void> loadLeaves() async {
    isLoading.value = true;
    try {
      leaves.value = await _repo.getLeaveRequests(
        auth.companyId,
        employeeId: auth.isAdmin ? null : auth.employeeId,
      );
    } catch (e) {
      debugPrint('[LeaveCtrl] loadLeaves error: $e');
      showError('Failed to load leave requests: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      data['company_id'] = auth.companyId;

      if (data['employee_id'] == null ||
          (data['employee_id'] as String).isEmpty) {
        throw Exception('Please select an employee');
      }
      if (data['from_date'] == null || (data['from_date'] as String).isEmpty) {
        throw Exception('Please select From Date');
      }
      if (data['to_date'] == null || (data['to_date'] as String).isEmpty) {
        throw Exception('Please select To Date');
      }

      // ── NEW: Check if employee has punched on any date in the leave range ──
      final fromDate = data['from_date'] as String;
      final toDate = data['to_date'] as String;
      final empId = data['employee_id'] as String;

      final punchCheck = await SupabaseService.client
          .from('attendance_logs')
          .select('date')
          .eq('company_id', auth.companyId)
          .eq('employee_id', empId)
          .gte('date', fromDate)
          .lte('date', toDate)
          .limit(1)
          .maybeSingle();

      if (punchCheck != null) {
        final punchedDate = punchCheck['date'] as String;
        throw Exception(
          'Employee has attendance punched on $punchedDate. Cannot apply leave on a day with existing punch records.',
        );
      }

      // ── Existing overlap check ──
      final hasOverlap = await _repo.hasOverlappingLeave(
        companyId: auth.companyId,
        employeeId: empId,
        fromDate: fromDate,
        toDate: toDate,
      );

      if (hasOverlap) {
        throw Exception(
          'Leave already applied for the selected date range. Please choose different dates.',
        );
      }

      final leave = await _repo.createLeave(data);
      leaves.insert(0, leave);
      showSuccess('Leave request submitted successfully');
    } catch (e) {
      debugPrint('[LeaveCtrl] create error: $e');
      showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approve(String id) async {
    try {
      final updated = await _repo.updateLeaveStatus(
        id,
        'approved',
        auth.userId,
      );
      _updateLocal(id, updated);
      showSuccess('Leave approved');
    } catch (e) {
      debugPrint('[LeaveCtrl] approve error: $e');
      showError('Failed to approve: $e');
    }
  }

  Future<void> reject(String id) async {
    try {
      final updated = await _repo.updateLeaveStatus(
        id,
        'rejected',
        auth.userId,
      );
      _updateLocal(id, updated);
      showSuccess('Leave rejected');
    } catch (e) {
      debugPrint('[LeaveCtrl] reject error: $e');
      showError('Failed to reject: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _repo.deleteLeave(id);
      leaves.removeWhere((l) => l.id == id);
      showSuccess('Leave deleted');
    } catch (e) {
      debugPrint('[LeaveCtrl] delete error: $e');
      showError('Failed to delete: $e');
    }
  }

  void _updateLocal(String id, LeaveRequestModel updated) {
    final idx = leaves.indexWhere((l) => l.id == id);
    if (idx != -1) leaves[idx] = updated;
  }

  void openLeaveForm(BuildContext context, LeaveController ctrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LeaveFormDialog(controller: ctrl),
    );
  }

  void confirmDelete(BuildContext context, LeaveController ctrl, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Leave Request'),
        content: const Text(
          'Are you sure you want to delete this leave request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ctrl.delete(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
