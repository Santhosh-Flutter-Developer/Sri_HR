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

  /// Returns true if [code] already exists in this company (case-insensitive).
  /// Pass [excludeId] to ignore the current record when editing.
  bool isDuplicateCode(String code, {String? excludeId}) {
    final normalized = code.trim().toUpperCase();
    return departments.any(
      (d) =>
          d.code.trim().toUpperCase() == normalized &&
          (excludeId == null || d.id != excludeId),
    );
  }

  /// Returns true if [name] already exists in this company (case-insensitive).
  /// Pass [excludeId] to ignore the current record when editing.
  bool isDuplicateName(String name, {String? excludeId}) {
    final normalized = name.trim().toLowerCase();
    return departments.any(
      (d) =>
          d.name.trim().toLowerCase() == normalized &&
          (excludeId == null || d.id != excludeId),
    );
  }

  Future<void> create(Map<String, dynamic> data) async {
    final code = (data['code'] as String? ?? '').trim().toUpperCase();
    final name = (data['name'] as String? ?? '').trim();

    if (isDuplicateCode(code)) {
      showError(
        'Department code "$code" already exists. Please use a unique code.',
        title: 'Duplicate Code',
      );
      return;
    }
    if (isDuplicateName(name)) {
      showError(
        'Department "$name" already exists. Please use a unique name.',
        title: 'Duplicate Name',
      );
      return;
    }

    try {
      data['company_id'] = auth.companyId;
      departments.add(await repo.createDepartment(data));
      showSuccess('Department created');
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> updateDepartment(String id, Map<String, dynamic> data) async {
    final code = (data['code'] as String? ?? '').trim().toUpperCase();
    final name = (data['name'] as String? ?? '').trim();

    if (isDuplicateCode(code, excludeId: id)) {
      showError(
        'Department code "$code" already exists. Please use a unique code.',
        title: 'Duplicate Code',
      );
      return;
    }
    if (isDuplicateName(name, excludeId: id)) {
      showError(
        'Department "$name" already exists. Please use a unique name.',
        title: 'Duplicate Name',
      );
      return;
    }

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
      Future.delayed(Duration(seconds: 2), () {
        loadDepartments();
      });
    } on PostgrestException catch (e) {
      String message = 'Something went wrong';

      if (e.code == '23503') {
        message =
            'Cannot delete this department because employees are assigned to it.';
      } else {
        message = e.message;
      }
      showError(message, title: "Delete Failed");
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
