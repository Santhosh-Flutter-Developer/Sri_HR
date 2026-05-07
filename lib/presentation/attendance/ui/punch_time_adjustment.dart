import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/attendance_log_model.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/attendance/widgets/chips.dart';
import 'package:sri_hr/presentation/attendance/widgets/punch_grid_view.dart';
import 'package:sri_hr/presentation/attendance/widgets/punch_table_view.dart';
import 'package:sri_hr/presentation/attendance/widgets/view_toggle_btn.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/empty_state.dart';
import 'package:sri_hr/widgets/sri_button.dart';

class PunchTimeAdjustment extends StatelessWidget {
  PunchTimeAdjustment({super.key});

  List<Map<String, dynamic>> buildRows(List<AttendanceLogModel> logs) {
    final Map<String, Map<String, dynamic>> grouped = {};
    for (final log in logs) {
      final key =
          '${log.employeeId}_${log.date.toIso8601String().substring(0, 10)}';
      grouped.putIfAbsent(
        key,
        () => {
          'employeeId': log.employeeId,
          'employee': log.employee,
          'date': log.date,
          'inLog': null,
          'outLog': null,
        },
      );
      if (log.punchType == PunchType.in_) {
        grouped[key]!['inLog'] = log;
      } else {
        grouped[key]!['outLog'] = log;
      }
    }
    final rows = grouped.values.toList();
    rows.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );
    return rows;
  }

  final controller = Get.isRegistered<AttendanceController>()
      ? Get.find<AttendanceController>()
      : Get.put(AttendanceController());

  final auth = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return AppShell(
      currentModule: 'punch_adjustment',
      title: 'Punch Adjustment',
      actions: [
        // View toggle
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
        const SizedBox(width: 10),
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
                  icon: Icon(Icons.add),
                ),
      ],
      child: Obx(() {
        final manualLogs = controller.logs.where((l) => l.isManual).toList();
        if (manualLogs.isEmpty) {
          return EmptyState(
            message: 'No manual punch adjustments',
            icon: Icons.tune_outlined,
            actionLabel: auth.canAdd('punch_adjustment')
                ? 'Add Adjustment'
                : null,
            onAction: () => controller.showForm(context, controller),
          );
        }
        final rows = buildRows(manualLogs);
        return Column(
          children: [
            // Summary
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: AppColors.surface,
              child: Row(
                children: [
                  Chips(
                    value: '${rows.length}',
                    label: 'Total Adjustments',
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  Chips(
                    value:
                        '${manualLogs.map((l) => l.employeeId).toSet().length}',
                    label: 'Employees',
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
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
                    ],
                  ),
                ),
              ),
            Expanded(
              child: controller.viewMode.value == 'table'
                  ? PunchTableView(
                      rows: rows,
                      controller: controller,
                      auth: auth,
                    )
                  : PunchGridView(
                      rows: rows,
                      controller: controller,
                      auth: auth,
                    ),
            ),
          ],
        );
      }),
    );
  }
}
