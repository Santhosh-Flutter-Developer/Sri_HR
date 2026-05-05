import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/data/models/permission_request_model.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/helper/helper.dart';
import 'package:sri_hr/presentation/permission_request/repository/permission_request_repository.dart';
import 'package:sri_hr/presentation/permission_request/ui/permission_form_dialog.dart';

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
      debugPrint('[PermCtrl] load error: $e');
      showError('Failed to load permissions');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      // Validate required fields
      if ((data['employee_id'] as String?)?.isEmpty != false) {
        throw Exception('Please select an employee');
      }
      if ((data['request_date'] as String?)?.isEmpty != false) {
        throw Exception('Please select a date');
      }
      if ((data['from_time'] as String?)?.isEmpty != false) {
        throw Exception('Please select From Time');
      }
      if ((data['to_time'] as String?)?.isEmpty != false) {
        throw Exception('Please select To Time');
      }

      data['company_id'] = auth.companyId;

      // Calculate minutes between from and to time
      try {
        final from = parseTime(data['from_time'] as String);
        final to = parseTime(data['to_time'] as String);
        if (to.isBefore(from) || to.isAtSameMomentAs(from)) {
          throw Exception('To Time must be after From Time');
        }
        data['minutes'] = to.difference(from).inMinutes;
      } catch (e) {
        if (e is Exception) rethrow;
      }

      debugPrint('[PermCtrl] creating: $data');
      final perm = await repo.createPermission(data);
      permission.insert(0, perm);
      showSuccess('Permission request submitted');
    } catch (e) {
      debugPrint('[PermCtrl] create error: $e');
      showError(e.toString().replaceAll('Exception: ', ''));
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  DateTime parseTime(String t) {
    final parts = t.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
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
      showError('Failed to approve: $e');
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
      showError('Failed to reject: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await repo.deletePermission(id);
      permission.removeWhere((p) => p.id == id);
      showSuccess('Permission deleted');
    } catch (e) {
      showError('Failed to delete: $e');
    }
  }

  void updateLocal(String id, PermissionRequestModel updated) {
    final idx = permission.indexWhere((p) => p.id == id);
    if (idx != -1) permission[idx] = updated;
  }

  void showForm(BuildContext context, PermissionRequestController controller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PermissionFormDialog(controller: controller),
    );
  }
}
