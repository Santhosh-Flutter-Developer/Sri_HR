import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/employee_status/controller/employee_status_controller.dart';
import 'package:sri_hr/presentation/employee_status/widgets/employee_status_card.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/empty_state.dart';
import 'package:sri_hr/widgets/loading_overlay.dart';
import 'package:sri_hr/widgets/sri_button.dart';

class EmployeeStatus extends StatelessWidget {
  EmployeeStatus({super.key});

  final controller = Get.isRegistered<EmployeeStatusController>()
      ? Get.find<EmployeeStatusController>()
      : Get.put(EmployeeStatusController());

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return AppShell(
      currentModule: 'employee_status',
      title: 'Employee Status',
      actions: [
        if (auth.canAdd('employee_status'))
          isWide
              ? SriButton(
                  label: "Add Employee Status",
                  onPressed: () =>
                      controller.showDialog(context, controller, null),
                  color: AppColors.accentGreen,
                  icon: Icons.add,
                )
              : IconButton(
                  onPressed: () =>
                      controller.showDialog(context, controller, null),
                  icon: Icon(Icons.add),
                ),

        const SizedBox(width: 16),
      ],
      child: Obx(
        () => controller.isLoading.value
            ? LoadingOverlay()
            : controller.statuses.isEmpty
            ? EmptyState(
                message: 'No Employee Status added yet',
                icon: Icons.toggle_on_rounded,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: controller.statuses.length,
                itemBuilder: (_, i) {
                  final item = controller.statuses[i];
                  return EmployeeStatusCard(
                    item: item,
                    onEdit: auth.canEdit('designation')
                        ? () => controller.showDialog(context, controller, item)
                        : null,
                    onDelete: auth.canDelete('designation')
                        ? () => controller.delete(item.id)
                        : null,
                  );
                },
              ),
      ),
    );
  }
}
