import 'dart:developer';

import 'package:get/get.dart';
import 'package:sri_hr/data/models/role_model.dart';
import 'package:sri_hr/data/models/role_permission_model.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/designation/repository/role_repository.dart';
import 'package:sri_hr/presentation/helper/helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

AuthController get auth => Get.find<AuthController>();

class RoleController extends GetxController {
  final repo = RoleRepository();
  final roles = <RoleModel>[].obs;
  final filteredroles = <RoleModel>[].obs;
  final selectedRole = Rxn<RoleModel>();
  final editingPermissions = <RolePermissionModel>[].obs;
  final isLoading = false.obs;
  final enable = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadRoles();
  }

  Future<void> loadRoles() async {
    isLoading.value = true;
    try {
      roles.value = await repo.getRoles(auth.companyId);
      filteredroles.value = roles.value;
    } catch (e) {
      log("ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void search(String query) {
    if (query.isEmpty) {
      filteredroles.value = roles;
    } else {
      filteredroles.value = roles.where((item) {
        final name = item.name.toString().toLowerCase();
        return name.contains(query.toString().toLowerCase());
      }).toList();
    }
  }

  Future<void> selectRole(RoleModel role) async {
    selectedRole.value = role;
    final perms = await repo.getPermissions(role.id);
    // Ensure all modules represented
    editingPermissions.value = allModules.map((m) {
      return perms.firstWhere(
        (p) => p.module == m,
        orElse: () => RolePermissionModel(
          id: '',
          companyId: auth.companyId,
          roleId: role.id,
          module: m,
        ),
      );
    }).toList();
  }

  Future<void> createRole(Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      data['company_id'] = auth.companyId;
      final role = await repo.createRole(data);
      roles.add(role);
      showSuccess('Designation created');
    } catch (e) {
      showError('Failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateRole(String id, Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      final role = await repo.updateRole(id, data);
      final idx = roles.indexWhere((r) => r.id == id);
      if (idx != -1) roles[idx] = role;
      showSuccess('Designation updated');
    } catch (e) {
      showError('Failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteRole(String id) async {
    try {
      await repo.deleteRole(id);
      roles.removeWhere((r) => r.id == id);
      showSuccess('Designation deleted');
      Future.delayed(Duration(seconds: 2), () {
        loadRoles();
      });
    } on PostgrestException catch (e) {
      String message = 'Something went wrong';

      if (e.code == '23503') {
        message =
            'Cannot delete this designation because employees are assigned to it.';
      } else {
        message = e.message;
      }
      showError(message, title: "Delete Failed");
    }
  }

  Future<void> savePermissions() async {
    if (selectedRole.value == null) return;
    isLoading.value = true;
    try {
      await repo.savePermissions(
        auth.companyId,
        selectedRole.value!.id,
        editingPermissions,
      );
      showSuccess('Permissions saved');
      enable.value = false;
    } catch (e) {
      showError('Failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void togglePermission(int idx, String type) {
    final p = editingPermissions[idx];
    editingPermissions[idx] = switch (type) {
      'view' => p.copyWith(canView: !p.canView),
      'add' => p.copyWith(canAdd: !p.canAdd),
      'edit' => p.copyWith(canEdit: !p.canEdit),
      'delete' => p.copyWith(canDelete: !p.canDelete),
      _ => p,
    };
  }

  static const allModules = [
    'dashboard',
    'designation',
    'company',
    'department',
    'employee_status',
    'salary_type',
    'employee',
    'holiday',
    'leave_request',
    'permission_request',
    'attendance_report',
    'punch_adjustment',
    'subscription',
  ];
}
