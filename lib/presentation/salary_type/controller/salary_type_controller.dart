import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/data/models/salary_type_model.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/helper/helper.dart';
import 'package:sri_hr/presentation/salary_type/repository/salary_type_repository.dart';
import 'package:sri_hr/presentation/salary_type/ui/salary_type_form.dart';

AuthController get auth => Get.find<AuthController>();

class SalaryTypeController extends GetxController {
  final repo = SalaryTypeRepository();
  final salaryTypes = <SalaryTypeModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      salaryTypes.value = await repo.getSalaryTypes(auth.companyId);
    } catch (e) {
      log("ERROR:$e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> create(String name) async {
    try {
      salaryTypes.add(
        await repo.create({'company_id': auth.companyId, 'name': name}),
      );
      showSuccess('Salary type created');
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> updateSalaryType(String id, String name) async {
    try {
      final s = await repo.update(id, {'name': name});
      final idx = salaryTypes.indexWhere((x) => x.id == id);
      if (idx != -1) salaryTypes[idx] = s;
      showSuccess('Salary type updated');
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await repo.delete(id);
      salaryTypes.removeWhere((x) => x.id == id);
      showSuccess('Salary type deleted');
    } catch (e) {
      showError('$e');
    }
  }

  void showDialog(BuildContext context,SalaryTypeController controller, dynamic item) {

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SalaryTypeForm(
          controller: controller,
          item: item,
           
        )
      ),
    );
  }

}
