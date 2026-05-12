import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/data/models/department_model.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/department/repository/department_repository.dart';
import 'package:sri_hr/presentation/department/ui/department_form.dart';
import 'package:sri_hr/presentation/helper/helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

AuthController get auth => Get.find<AuthController>();

class DepartmentController extends GetxController {
  final repo = DepartmentRepository();
  final departments = <DepartmentModel>[].obs;
  final filteredDepartments = <DepartmentModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDepartments();
  }

  Future<void> loadDepartments() async {
    isLoading.value = true;
    try {
      departments.value = await repo.getDepartments(auth.companyId);
      filteredDepartments.value = departments.value;
    } catch (e) {
      log("ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void search(String query) {
    if (query.isEmpty) {
      filteredDepartments.value = departments;
    } else {
      filteredDepartments.value = departments.where((item) {
        final name = item.name.toString().toLowerCase();
        return name.contains(query.toString().toLowerCase());
      }).toList();
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    try {
      data['company_id'] = auth.companyId;
      departments.add(await repo.createDepartment(data));
      showSuccess('Department created');
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> updateDepartment(String id, Map<String, dynamic> data) async {
    try {
      final d = await repo.updateDepartment(id, data);
      final idx = departments.indexWhere((x) => x.id == id);
      if (idx != -1) departments[idx] = d;
      showSuccess('Department updated');
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await repo.deleteDepartment(id);
      departments.removeWhere((x) => x.id == id);
      showSuccess('Department deleted');
    } on PostgrestException catch (e) {
      String message = 'Something went wrong';

      if (e.code == '23503') {
        message =
            'Cannot delete this department because employees are assigned to it.';
      } else {
        message = e.message;
      }
      showError(message,title: "Delete Failed");
    }
  }

  void showForm(
    BuildContext context,
    DepartmentController controller, {
    dynamic dept,
  }) {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.all(4.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: DepartmentForm(dept: dept, controller: controller),
      ),
    );
  }
}
