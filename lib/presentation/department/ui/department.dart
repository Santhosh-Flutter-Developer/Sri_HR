import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/department/controller/department_controller.dart';
import 'package:sri_hr/presentation/department/widgets/department_card.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/empty_state.dart';
import 'package:sri_hr/widgets/loading_overlay.dart';
import 'package:sri_hr/widgets/sri_button.dart';

class Department extends StatelessWidget {
  Department({super.key});

  final controller = Get.isRegistered<DepartmentController>()
      ? Get.find<DepartmentController>()
      : Get.put(DepartmentController());
  final auth = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return AppShell(
      currentModule: "department",
      title: "Departments",
      actions: [
        if (auth.canAdd('department'))
          isWide
              ? SriButton(
                  icon: Icons.add,
                  label: "Add Department",
                  onPressed: () => controller.showForm(context, controller),
                )
              : IconButton(
                  onPressed: () => controller.showForm(context, controller),
                  icon: Icon(Icons.add),
                ),
      ],
      child: Obx(
        () => controller.isLoading.value
            ? const LoadingOverlay()
            : controller.departments.isEmpty
            ? EmptyState(
                message: 'No departments yet',
                icon: Icons.account_tree_outlined,
                actionLabel: auth.canAdd('department')
                    ? 'Add Department'
                    : null,
                onAction: () => controller.showForm(context, controller),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: controller.departments.length,
                itemBuilder: (_, i) {
                  final d = controller.departments[i];
                  return DepartmentCard(
                    item: d,
                  );
                },
              ),
      ),
    );
  }
}
