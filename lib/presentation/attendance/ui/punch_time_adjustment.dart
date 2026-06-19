import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/attendance/widgets/chips.dart';
import 'package:sri_hr/presentation/attendance/widgets/punch_date_range_strip.dart';
import 'package:sri_hr/presentation/attendance/widgets/punch_filter_sheet.dart';
import 'package:sri_hr/presentation/attendance/widgets/punch_grid_view.dart';
import 'package:sri_hr/presentation/attendance/widgets/punch_pagination_bar.dart';
import 'package:sri_hr/presentation/attendance/widgets/punch_table_view.dart';
import 'package:sri_hr/presentation/attendance/widgets/view_toggle_btn.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/empty_state.dart';
import 'package:sri_hr/widgets/loading_overlay.dart';
import 'package:sri_hr/widgets/sri_button.dart';

class PunchTimeAdjustment extends StatelessWidget {
  PunchTimeAdjustment({super.key});

  final controller = Get.isRegistered<AttendanceController>()
      ? Get.find<AttendanceController>()
      : Get.put(AttendanceController());

  final auth = Get.find<AuthController>();

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PunchFilterSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return SafeArea(
      top: false,
      child: AppShell(
        currentModule: 'punch_adjustment',
        title: 'Punch Adjustment',
        actions: [
          // View toggle (wide)
          if (isWide)
            Obx(
              () => Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    ViewToggleBtn(
                      icon: Icons.table_rows_rounded,
                      tooltip: 'Table',
                      selected: controller.viewMode.value == 'table',
                      onTap: () => controller.viewMode.value = 'table',
                    ),
                    ViewToggleBtn(
                      icon: Icons.grid_view_rounded,
                      tooltip: 'Grid',
                      selected: controller.viewMode.value == 'grid',
                      onTap: () => controller.viewMode.value = 'grid',
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),
          // Filter button
          isWide
              ? SriButton(
                  label: 'Filter',
                  onPressed: () => _showFilterSheet(context),
                  icon: Icons.filter_list_rounded,
                  isOutlined: true,
                )
              : IconButton(
                  onPressed: () => _showFilterSheet(context),
                  icon: const Icon(Icons.filter_list_rounded),
                ),
          const SizedBox(width: 8),
          // Add punch button
          if (auth.canAdd('punch_adjustment'))
            isWide
                ? SriButton(
                    onPressed: () => controller.showForm(context, controller),
                    icon: Icons.add,
                    label: 'Add Punch',
                    color: AppColors.warning,
                  )
                : IconButton(
                    onPressed: () => controller.showForm(context, controller),
                    icon: const Icon(Icons.add),
                  ),
        ],
        child: Column(
          children: [
            // Date range strip
            PunchDateRangeStrip(
              controller: controller,
              onTap: () => _showFilterSheet(context),
            ),

            // Content
            Expanded(
              child: Obx(() {
                if (controller.isPunchLoading.value) {
                  return const LoadingOverlay();
                }

                final allRows = controller.groupedPunchRows;

                if (allRows.isEmpty) {
                  return EmptyState(
                    message: 'No punch adjustments for the selected period',
                    icon: Icons.tune_outlined,
                    actionLabel: 'Change Filter',
                    color: AppColors.accentOrange,
                    onAction: () => _showFilterSheet(context),
                  );
                }

                return Column(
                  children: [
                    // Summary strip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      color: AppColors.surface,
                      child: Row(
                        children: [
                          Obx(
                            () => Chips(
                              value: '${controller.groupedPunchRows.length}',
                              label: 'Total Adjustments',
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Obx(
                            () => Chips(
                              value:
                                  '${controller.punchLogs.map((l) => l.employeeId).toSet().length}',
                              label: 'Employees',
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Mobile: rows per page + view toggle row
                    if (!isWide)
                      Obx(
                        () => Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            children: [
                              // Rows per page
                              const Text(
                                'Rows per page:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                height: 32,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: controller.punchPageSize.value,
                                    isDense: true,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    items: controller.pageSizeOptions
                                        .map(
                                          (v) => DropdownMenuItem(
                                            value: v,
                                            child: Text('$v'),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        controller.setPunchPageSize(v);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // View toggle
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    ViewToggleBtn(
                                      icon: Icons.table_rows_rounded,
                                      tooltip: 'Table',
                                      selected:
                                          controller.viewMode.value == 'table',
                                      onTap: () =>
                                          controller.viewMode.value = 'table',
                                    ),
                                    ViewToggleBtn(
                                      icon: Icons.grid_view_rounded,
                                      tooltip: 'Grid',
                                      selected:
                                          controller.viewMode.value == 'grid',
                                      onTap: () =>
                                          controller.viewMode.value = 'grid',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Table / Grid
                    Expanded(
                      child: Obx(
                        () => controller.viewMode.value == 'table'
                            ? PunchTableView(
                                rows: controller.pagedPunchRows,
                                controller: controller,
                                auth: auth,
                              )
                            : PunchGridView(
                                rows: controller.pagedPunchRows,
                                controller: controller,
                                auth: auth,
                              ),
                      ),
                    ),

                    // Pagination bar
                    PunchPaginationBar(controller: controller),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}