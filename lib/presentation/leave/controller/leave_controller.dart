import 'package:get/get.dart';
import 'package:sri_hr/data/models/leave_request_model.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/helper/helper.dart';
import 'package:sri_hr/presentation/leave/repository/leave_repository.dart';

AuthController get auth => Get.find<AuthController>();

class LeaveController extends GetxController {
  final repo = LeaveRepository();
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
    try {
      isLoading.value = true;
      final data = await repo.getLeaveRequests(auth.companyId);
      leaves.assignAll(data);
    } catch (e) {
      showError('Failed to load leave requests');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    try {
      data['company_id'] = auth.companyId;
      leaves.insert(0, await repo.createLeave(data));
      showSuccess('Leave request submitted');
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> approve(String id) async {
    try {
      final updated = await repo.updateLeaveStatus(
        id,
        'approved',
        auth.userId,
      );
      updateLocal(id, updated);
      showSuccess('Leave approved');
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> reject(String id) async {
    try {
      final updated = await repo.updateLeaveStatus(
        id,
        'rejected',
        auth.userId,
      );
      updateLocal(id, updated);
      showSuccess('Leave rejected');
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await repo.deleteLeave(id);
      leaves.removeWhere((l) => l.id == id);
      showSuccess('Leave deleted');
    } catch (e) {
      showError('$e');
    }
  }

  void updateLocal(String id, LeaveRequestModel updated) {
    final idx = leaves.indexWhere((l) => l.id == id);
    if (idx != -1) leaves[idx] = updated;
  }
}
