import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/data/models/employee_status_model.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/employee_status/repository/employee_status_repository.dart';
import 'package:sri_hr/presentation/employee_status/ui/employee_status_form.dart';
import 'package:sri_hr/presentation/helper/helper.dart';

AuthController get auth => Get.find<AuthController>();

class EmployeeStatusController extends GetxController {
  final repo = EmployeeStatusRepository();
  final statuses = <EmployeeStatusModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      statuses.value = await repo.getStatuses(auth.companyId);
    } catch (e) {
      log("ERROR:$e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> create(String name) async {
    try {
      statuses.add(
        await repo.create({'company_id': auth.companyId, 'name': name}),
      );
      showSuccess('Status created');
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> updateEmployeeStatus(String id, String name) async {
    try {
      final s = await repo.update(id, {'name': name});
      final idx = statuses.indexWhere((x) => x.id == id);
      if (idx != -1) statuses[idx] = s;
      showSuccess('Status updated');
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await repo.delete(id);
      statuses.removeWhere((x) => x.id == id);
      showSuccess('Status deleted');
    } catch (e) {
      showError('$e');
    }
  }

  void showDialog(BuildContext context,EmployeeStatusController controller, dynamic item) {

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: EmployeeStatusForm(
          item: item,
          controller:controller, 
        )
      ),
    );
  }
}
