import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/data/models/salary_type_model.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/helper/helper.dart';
import 'package:sri_hr/presentation/salary_type/repository/salary_type_repository.dart';
import 'package:sri_hr/presentation/salary_type/ui/salary_type_form.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

AuthController get auth => Get.find<AuthController>();

class SalaryTypeController extends GetxController {
  final repo = SalaryTypeRepository();
  final salaryTypes = <SalaryTypeModel>[].obs;
  final filteredSalaryTypes = <SalaryTypeModel>[].obs;
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
      filteredSalaryTypes.value = salaryTypes.value;
    } catch (e) {
      log("ERROR:$e");
    } finally {
      isLoading.value = false;
    }
  }

  void search(String query) {
    if (query.isEmpty) {
      filteredSalaryTypes.value = salaryTypes;
    } else {
      filteredSalaryTypes.value = salaryTypes.where((item) {
        final name = item.name.toString().toLowerCase();
        return name.contains(query.toString().toLowerCase());
      }).toList();
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
      Future.delayed(Duration(seconds: 2), () {
        load();
      });
    } on PostgrestException catch (e) {
      String message = 'Something went wrong';

      if (e.code == '23503') {
        message =
            'Cannot delete this salary type because employees are assigned to it.';
      } else {
        message = e.message;
      }
      showError(message, title: "Delete Failed");
    }
  }

  void showDialog(
    BuildContext context,
    SalaryTypeController controller,
    dynamic item,
  ) {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.all(4.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SalaryTypeForm(controller: controller, item: item),
      ),
    );
  }
}
