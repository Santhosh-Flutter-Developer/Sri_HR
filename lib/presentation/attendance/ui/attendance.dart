import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/attendance/widgets/date_range_strip.dart';
import 'package:sri_hr/presentation/attendance/widgets/grid_view.dart';
import 'package:sri_hr/presentation/attendance/widgets/summary_strip.dart';
import 'package:sri_hr/presentation/attendance/widgets/table_view.dart';
import 'package:sri_hr/presentation/attendance/widgets/view_toggle_btn.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/empty_state.dart';
import 'package:sri_hr/widgets/loading_overlay.dart';
import 'package:sri_hr/widgets/sri_button.dart';

class Attendance extends StatelessWidget {
  Attendance({super.key});

  final controller = Get.isRegistered<AttendanceController>()
      ? Get.find<AttendanceController>()
      : Get.put(AttendanceController());

  final auth = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return SafeArea(
      top: false,
      child: AppShell(
        currentModule: 'attendance_report',
        title: 'Attendance Report',
        actions: [
          if (isWide)
            Obx(
              () => Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    ViewToggleBtn(
                      icon: Icons.table_rows_rounded,
                      tooltip: 'Table View',
                      selected: controller.viewMode.value == 'table',
                      onTap: () => controller.viewMode.value = 'table',
                    ),
                    ViewToggleBtn(
                      icon: Icons.grid_view_rounded,
                      tooltip: 'Grid View',
                      selected: controller.viewMode.value == 'grid',
                      onTap: () => controller.viewMode.value = 'grid',
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 10.0),
          isWide
              ? SriButton(
                  label: "Filter",
                  onPressed: () =>
                      controller.showFilterSheet(context, controller),
                  icon: Icons.filter_list_rounded,
                  isOutlined: true,
                )
              : IconButton(
                  onPressed: () =>
                      controller.showFilterSheet(context, controller),
                  icon: Icon(Icons.filter_list_rounded),
                ),
          const SizedBox(width: 10.0),
          // SriButton(
          //   label: "Export",
          //   onPressed: () => controller.exportCSV(context, controller),
          //   icon: Icons.download_rounded,
          // ),
          // const SizedBox(width: 16.0),
        ],
        child: Column(
          children: [
            // Date range strip
            DateRangeStrip(
              controller: controller,
              onTap: () => controller.showFilterSheet(context, controller),
            ),
            // Summary
            SummaryStrip(controller: controller),
            const Divider(height: 1.0, color: AppColors.border),
            if (!isWide)
              Obx(
                () => Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            ViewToggleBtn(
                              icon: Icons.table_rows_rounded,
                              tooltip: 'Table View',
                              selected: controller.viewMode.value == 'table',
                              onTap: () => controller.viewMode.value = 'table',
                            ),
                            ViewToggleBtn(
                              icon: Icons.grid_view_rounded,
                              tooltip: 'Grid View',
                              selected: controller.viewMode.value == 'grid',
                              onTap: () => controller.viewMode.value = 'grid',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Content
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const LoadingOverlay();
                }
                final rows = controller.groupedByEmployeeDate;
                if (rows.isEmpty) {
                  return EmptyState(
                    message: "No attendance records for the selected period",
                    icon: Icons.assessment_outlined,
                    actionLabel: "Change Filter",
                    onAction: () =>
                        controller.showFilterSheet(context, controller),
                  );
                }
                return controller.viewMode.value == 'table'
                    ? TableView(rows: rows, controller: controller, auth: auth)
                    : GridedView(rows: rows, controller: controller, auth: auth);
              }),
            ),
          ],
        ),
      ),
    );
  }
}
