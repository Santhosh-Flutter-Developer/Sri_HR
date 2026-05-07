import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/department/controller/department_controller.dart';
import 'package:sri_hr/presentation/department/widgets/department_card.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/empty_state.dart';
import 'package:sri_hr/widgets/loading_overlay.dart';
import 'package:sri_hr/widgets/sri_button.dart';
import 'package:sri_hr/widgets/sri_search_bar.dart';

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
      child: RefreshIndicator(
        onRefresh: controller.loadDepartments,
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
                      onPressed: controller.loadDepartments,
                      icon: Icon(Icons.refresh, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? const LoadingOverlay()
                    : controller.filteredDepartments.isEmpty
                    ? EmptyState(
                        message: 'No departments yet',
                        icon: Icons.account_tree_outlined,
                        actionLabel: auth.canAdd('department')
                            ? 'Add Department'
                            : null,
                        onAction: () =>
                            controller.showForm(context, controller),
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
                                controller.filteredDepartments.length,
                                (i) {
                                  final d = controller.filteredDepartments[i];
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
                                      child: DepartmentCard(item: d),
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
        label: "Search Departments",
        prefixIcon: Icons.search,
        onChanged: controller.search,
      ),
    );
  }
}
