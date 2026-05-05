import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/permission_request_model.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/employee/controller/employee_controller.dart';
import 'package:sri_hr/presentation/helper/helper.dart';
import 'package:sri_hr/presentation/permission_request/repository/permission_request_repository.dart';
import 'package:sri_hr/widgets/sri_dropdown.dart';
import 'package:sri_hr/widgets/sri_textfield.dart';

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

  void showForm(BuildContext context, PermissionRequestController controller) {
    final empCtrl = Get.find<EmployeeController>();
    final formKey = GlobalKey<FormState>();
    final dateCtrl = TextEditingController();
    final fromCtrl = TextEditingController();
    final toCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String? empId;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Container(
          constraints: BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
                decoration: const BoxDecoration(
                  color: AppColors.info,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    const Text(
                      'Permission Request',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              StatefulBuilder(
                builder: (context, setState) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        Obx(
                          () => SriDropdown<String>(
                            value: empId,
                            label: 'Employee *',
                            prefixIcon: Icons.person_rounded,
                            items: empCtrl.employees
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.id,
                                    child: Text(e.fullName),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => empId = v),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SriTextField(
                          controller: dateCtrl,
                          label: 'Date *',
                          prefixIcon: Icons.calendar_today_rounded,
                          readOnly: true,
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 30),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 30),
                              ),
                            );
                            if (d != null) {
                              setState(
                                () => dateCtrl.text = d
                                    .toIso8601String()
                                    .substring(0, 10),
                              );
                            }
                          },
                          validator: (v) =>
                              v?.isEmpty == true ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SriTextField(
                                controller: fromCtrl,
                                label: 'From Time',
                                hint: '10:00',
                                prefixIcon: Icons.access_time_rounded,
                                keyboardType: TextInputType.datetime,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SriTextField(
                                controller: toCtrl,
                                label: 'To Time',
                                hint: '11:00',
                                prefixIcon: Icons.access_time_filled_rounded,
                                keyboardType: TextInputType.datetime,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SriTextField(
                          controller: reasonCtrl,
                          label: 'Reason',
                          maxLines: 2,
                          prefixIcon: Icons.notes_rounded,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Get.back(),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }
                                  controller.create({
                                    'employee_id': empId,
                                    'request_date': dateCtrl.text,
                                    'from_time': fromCtrl.text,
                                    'to_time': toCtrl.text,
                                    'reason': reasonCtrl.text,
                                  });
                                  Get.back();
                                },
                                child: const Text('Submit'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
