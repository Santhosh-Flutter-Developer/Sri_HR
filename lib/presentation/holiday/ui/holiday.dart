import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/holiday/controller/holiday_controller.dart';
import 'package:sri_hr/presentation/holiday/widgets/holiday_card.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/empty_state.dart';
import 'package:sri_hr/widgets/loading_overlay.dart';
import 'package:sri_hr/widgets/sri_button.dart';
import 'package:sri_hr/widgets/sri_search_bar.dart';

class Holiday extends StatelessWidget {
  Holiday({super.key});

  final controller = Get.isRegistered<HolidayController>()
      ? Get.find<HolidayController>()
      : Get.put(HolidayController());

  final auth = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return SafeArea(
      top: false,
      child: AppShell(
        currentModule: 'holiday',
        title: 'Holiday Entry',
        actions: [
          if (auth.canAdd('holiday'))
            isWide
                ? SriButton(
                    label: 'Add Holiday',
                    color: AppColors.accent,
                    onPressed: () =>
                        controller.showForm(context, controller, holiday: null),
                    icon: Icons.add,
                  )
                : IconButton(
                    onPressed: () =>
                        controller.showForm(context, controller, holiday: null),
                    icon: Icon(Icons.add),
                  ),
        ],
        child: RefreshIndicator(
          onRefresh: controller.loadHolidays,
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
                        onPressed: controller.loadHolidays,
                        icon: Icon(Icons.refresh, color: AppColors.primary),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Obx(
                  () => controller.isLoading.value
                      ? LoadingOverlay()
                      : controller.filteredholidays.isEmpty
                      ? EmptyState(
                          message:
                              'No holidays added for ${controller.selectedYear.value}',
                          icon: Icons.celebration_outlined,
                          color: AppColors.accent,
                          actionLabel: auth.canAdd('holiday')
                              ? 'Add Holiday'
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
                                  controller.filteredholidays.length,
                                  (i) {
                                    final h = controller.filteredholidays[i];
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
                                        child: HolidayCard(
                                          item: h,
                                          onEdit: auth.canEdit('holiday')
                                              ? () => controller.showForm(
                                                  context,
                                                  controller,
                                                  holiday: h,
                                                )
                                              : null,
                                          onDelete: auth.canDelete('holiday')
                                              ? () => controller.confirmDelete(
                                                  context,
                                                  h.id,
                                                )
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
        label: "Search Holidays",
        prefixIcon: Icons.search,
        onChanged: controller.search,
      ),
    );
  }
}
