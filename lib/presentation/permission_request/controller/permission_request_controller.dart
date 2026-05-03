import 'package:get/get.dart';
import 'package:sri_hr/data/models/permission_request_model.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/helper/helper.dart';
import 'package:sri_hr/presentation/permission_request/repository/permission_request_repository.dart';

AuthController get auth => Get.find<AuthController>();

class PermissionRequestController extends GetxController {
  final repo = PermissionRepository();
  final permission = <PermissionRequestModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      permission.value = await repo.getPermissions(auth.companyId);
    } catch (e) {
      showError('Failed to load permissions');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    try {
      data['company_id'] = auth.companyId;
      permission.insert(0, await repo.createPermission(data));
      showSuccess('Permission request submitted');
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> approve(String id) async {
    try {
      final updated = await repo.updatePermissionStatus(
        id,
        'approved',
        auth.userId,
      );
      updateLocal(id, updated);
      showSuccess('Permission approved');
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> reject(String id) async {
    try {
      final updated = await repo.updatePermissionStatus(
        id,
        'rejected',
        auth.userId,
      );
      updateLocal(id, updated);
      showSuccess('Permission rejected');
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await repo.deletePermission(id);
      permission.removeWhere((p) => p.id == id);
      showSuccess('Permission deleted');
    } catch (e) {
      showError('$e');
    }
  }

  void updateLocal(String id, PermissionRequestModel updated) {
    final idx = permission.indexWhere((p) => p.id == id);
    if (idx != -1) permission[idx] = updated;
  }
}
