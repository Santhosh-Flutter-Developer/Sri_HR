import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/salary_type/controller/salary_type_controller.dart';
import 'package:sri_hr/presentation/salary_type/widgets/salary_type_card.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/empty_state.dart';
import 'package:sri_hr/widgets/loading_overlay.dart';
import 'package:sri_hr/widgets/sri_button.dart';
import 'package:sri_hr/widgets/sri_search_bar.dart';

class SalaryType extends StatelessWidget {
  SalaryType({super.key});

  final controller = Get.isRegistered<SalaryTypeController>()
      ? Get.find<SalaryTypeController>()
      : Get.put(SalaryTypeController());
  final auth = Get.find<AuthController>();
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return SafeArea(
      top: false,
      child: AppShell(
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
                      : controller.filteredSalaryTypes.isEmpty
                      ? EmptyState(
                          message: "No Salary Types added yet",
                          icon: Icons.payments_rounded,
                          actionLabel: auth.canAdd('salary_type')
                              ? 'Add Salary Type'
                              : null,
                          color: AppColors.accentOrange,
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
                                  controller.filteredSalaryTypes.length,
                                  (i) {
                                    final item =
                                        controller.filteredSalaryTypes[i];
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
                                        child: SalaryTypeCard(
                                          item: item,
                                          onEdit: auth.canEdit('salary_type')
                                              ? () => controller.showDialog(
                                                  context,
                                                  controller,
                                                  item,
                                                )
                                              : null,
                                          onDelete: auth.canDelete('salary_type')
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
        label: "Search Salary Types",
        prefixIcon: Icons.search,
        onChanged: controller.search,
      ),
    );
  }
}
