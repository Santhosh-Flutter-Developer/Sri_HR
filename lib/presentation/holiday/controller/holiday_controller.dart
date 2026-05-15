import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/data/models/holiday_model.dart';
import 'package:sri_hr/data/utils/network_time.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/helper/helper.dart';
import 'package:sri_hr/presentation/holiday/repository/holiday_repository.dart';
import 'package:sri_hr/presentation/holiday/ui/holiday_form.dart';

AuthController get auth => Get.find<AuthController>();

class HolidayController extends GetxController {
  final repo = HolidayRepository();
  final holidays = <HolidayModel>[].obs;
  final filteredholidays = <HolidayModel>[].obs;
  final isLoading = false.obs;
  final selectedYear = NetworkTime.now().year.obs;

  @override
  void onInit() {
    super.onInit();
    loadHolidays();
  }

  Future<void> loadHolidays() async {
    isLoading.value = true;
    try {
      holidays.value = await repo.getHolidays(
        auth.companyId,
        year: selectedYear.value,
      );
      filteredholidays.value = holidays.value;
    } catch (e) {
      log("ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void search(String query) {
    if (query.isEmpty) {
      filteredholidays.value = holidays;
    } else {
      filteredholidays.value = holidays.where((item) {
        final name = item.reason.toString().toLowerCase();
        return name.contains(query.toString().toLowerCase());
      }).toList();
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    try {
      data['company_id'] = auth.companyId;
      holidays.add(await repo.createHoliday(data));
      showSuccess('Holiday added');
      Future.delayed(Duration(seconds: 2), () {
        loadHolidays();
      });
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> updateHoliday(String id, Map<String, dynamic> data) async {
    try {
      final h = await repo.updateHoliday(id, data);
      final idx = holidays.indexWhere((x) => x.id == id);
      if (idx != -1) holidays[idx] = h;
      showSuccess('Holiday updated');
      Future.delayed(Duration(seconds: 2), () {
        loadHolidays();
      });
    } catch (e) {
      showError('$e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await repo.deleteHoliday(id);
      holidays.removeWhere((x) => x.id == id);
      showSuccess('Holiday deleted');
      Future.delayed(Duration(seconds: 2), () {
        loadHolidays();
      });
    } catch (e) {
      showError('$e');
    }
  }

  void changeYear(int year) {
    selectedYear.value = year;
    loadHolidays();
  }

  void showForm(
    BuildContext context,
    HolidayController controller, {
    dynamic holiday,
  }) {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.all(4.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: HolidayForm(controller: controller, item: holiday),
      ),
    );
  }
}
