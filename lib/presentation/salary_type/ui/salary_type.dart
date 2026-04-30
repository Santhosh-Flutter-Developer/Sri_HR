import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/salary_type/controller/salary_type_controller.dart';
import 'package:sri_hr/presentation/salary_type/widgets/salary_type_card.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/empty_state.dart';
import 'package:sri_hr/widgets/loading_overlay.dart';
import 'package:sri_hr/widgets/sri_button.dart';

class SalaryType extends StatelessWidget {
  SalaryType({super.key});

  final controller = Get.isRegistered<SalaryTypeController>()
      ? Get.find<SalaryTypeController>()
      : Get.put(SalaryTypeController());
  final auth = Get.find<AuthController>();
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return AppShell(
      currentModule: "salary_type",
      title: "Salary Types",
      actions: [
        if (auth.canAdd("salary_type"))
          isWide
              ? SriButton(
                  label: "Add Salary Type",
                  icon: Icons.add,
                  color: AppColors.accentOrange,
                  onPressed: () =>
                      controller.showDialog(context, controller, null),
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
            : controller.salaryTypes.isEmpty
            ? EmptyState(
                message: "No Salary Types added yet",
                icon: Icons.payments_rounded,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: controller.salaryTypes.length,
                itemBuilder: (_, i) {
                  final item = controller.salaryTypes[i];
                  return SalaryTypeCard(
                    item: item,
                    onEdit: auth.canEdit('salary_type')
                        ? () => controller.showDialog(context, controller, item)
                        : null,
                    onDelete: auth.canDelete('salary_type')
                        ? () => controller.delete(item.id)
                        : null,
                  );
                },
              ),
      ),
    );
  }
}
