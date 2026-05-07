import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/employee/controller/employee_controller.dart';
import 'package:sri_hr/presentation/employee/widgets/employee_card.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/empty_state.dart';
import 'package:sri_hr/widgets/loading_overlay.dart';
import 'package:sri_hr/widgets/sri_button.dart';

class Employee extends StatelessWidget {
  Employee({super.key});

  final controller = Get.isRegistered<EmployeeController>()
      ? Get.find<EmployeeController>()
      : Get.put(EmployeeController());

  final auth = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return AppShell(
      currentModule: 'employee',
      title: 'Employee',
      actions: [
        if (auth.canAdd('employee'))
          isWide
              ? SriButton(
                  label: 'Add Employee',
                  onPressed: () => controller.openForm(context, controller),
                  icon: Icons.add,
                )
              : IconButton(
                  onPressed: () => controller.openForm(context, controller),
                  icon: const Icon(Icons.add),
                ),
      ],
      child: RefreshIndicator(
        onRefresh: controller.loadEmployees,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isWide ? 24.0 : 10.0,
                      20,
                      isWide ? 24.0 : 10.0,
                      0,
                    ),
                    child: TextField(
                      onChanged: (v) => controller.searchQuery.value = v,
                      decoration: InputDecoration(
                        hintText: 'Search by name, code or mobile…',
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                    ),
                  ),
                ),
                if (isWide)
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 8.0,
                      top: 10.0,
                      // bottom: 20.0,
                    ),
                    child: IconButton(
                      onPressed: controller.loadEmployees,
                      icon: Icon(Icons.refresh, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? const LoadingOverlay()
                    : controller.filteredEmployees.isEmpty
                    ? EmptyState(
                        message: 'No employees found',
                        icon: Icons.people_outline,
                        actionLabel: auth.canAdd('employee')
                            ? 'Add Employee'
                            : null,
                        onAction: () =>
                            controller.openForm(context, controller),
                      )
                    : ListView(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: 10.0,
                              left: isWide ? 24.0 : 10.0,
                              right: isWide ? 24.0 : 10.0,
                              bottom: 10.0,
                            ),
                            child: ResponsiveGridRow(
                              children: List.generate(
                                controller.filteredEmployees.length,
                                (i) {
                                  return ResponsiveGridCol(
                                    xl: 4,
                                    lg: 4,
                                    md: 6,
                                    sm: 12,
                                    xs: 12,
                                    child: EmployeeCard(
                                      employee: controller.filteredEmployees[i],
                                      onEdit: auth.canEdit('employee')
                                          ? () => controller.openForm(
                                              context,
                                              controller,
                                              employee: controller
                                                  .filteredEmployees[i],
                                            )
                                          : null,
                                      onDelete: auth.canDelete('employee')
                                          ? () => controller.confirmDelete(
                                              context,
                                              controller,
                                              controller
                                                  .filteredEmployees[i]
                                                  .id,
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
