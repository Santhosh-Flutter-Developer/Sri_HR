import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/employee_status/controller/employee_status_controller.dart';
import 'package:sri_hr/presentation/employee_status/widgets/employee_status_card.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/empty_state.dart';
import 'package:sri_hr/widgets/loading_overlay.dart';
import 'package:sri_hr/widgets/sri_button.dart';
import 'package:sri_hr/widgets/sri_search_bar.dart';

class EmployeeStatus extends StatelessWidget {
  EmployeeStatus({super.key});

  final controller = Get.isRegistered<EmployeeStatusController>()
      ? Get.find<EmployeeStatusController>()
      : Get.put(EmployeeStatusController());

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return SafeArea(
      top: false,
      child: AppShell(
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
        ],
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: searchWidget(context)),
                  if (isWide)
                    Padding(
                      padding: const EdgeInsets.only(
                        right: 8.0,
                        top: 10.0,
                        // bottom: 20.0,
                      ),
                      child: IconButton(
                        onPressed: controller.load,
                        icon: Icon(Icons.refresh, color: AppColors.primary),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Obx(
                  () => controller.isLoading.value
                      ? LoadingOverlay()
                      : controller.filteredStatuses.isEmpty
                      ? EmptyState(
                          message: 'No Employee Status added yet',
                          icon: Icons.toggle_on_rounded,
                          actionLabel: auth.canAdd('employee_status')
                              ? 'Add Employee Status'
                              : null,
                          color: AppColors.accentGreen,
                          onAction: () =>
                              controller.showDialog(context, controller, null),
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
                                  controller.filteredStatuses.length,
                                  (i) {
                                    final item = controller.filteredStatuses[i];
                                    return ResponsiveGridCol(
                                      xl: 4,
                                      lg: 4,
                                      md: 6,
                                      sm: 12,
                                      xs: 12,
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right: isWide ? 8.0 : 0.0,
                                        ),
                                        child: EmployeeStatusCard(
                                          item: item,
                                          onEdit: auth.canEdit('employee_status')
                                              ? () => controller.showDialog(
                                                  context,
                                                  controller,
                                                  item,
                                                )
                                              : null,
                                          onDelete: auth.canDelete('employee_status')
                                              ? () => controller.delete(item.id)
                                              : null,
                                        ),
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
      ),
    );
  }

  Widget searchWidget(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return Padding(
      padding: EdgeInsets.only(
        top: isWide ? 24.0 : 10.0,
        left: isWide ? 24.0 : 10.0,
        right: 10.0,
        bottom: 10.0,
      ),
      child: SriSearchBar(
        label: "Search Employee Status",
        prefixIcon: Icons.search,
        onChanged: controller.search,
      ),
    );
  }
}
