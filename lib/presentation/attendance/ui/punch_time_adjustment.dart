import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/attendance_log_model.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/attendance/widgets/summary_chip.dart';
import 'package:sri_hr/presentation/attendance/widgets/table_header.dart';
import 'package:sri_hr/presentation/attendance/widgets/table_row.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/empty_state.dart';
import 'package:sri_hr/widgets/sri_button.dart';

class PunchTimeAdjustment extends StatefulWidget {
  const PunchTimeAdjustment({super.key});

  @override
  State<PunchTimeAdjustment> createState() => _PunchTimeAdjustmentState();
}

class _PunchTimeAdjustmentState extends State<PunchTimeAdjustment> {
  final controller = Get.isRegistered<AttendanceController>()
      ? Get.find<AttendanceController>()
      : Get.put(AttendanceController());

  final auth = Get.find<AuthController>();

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

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return AppShell(
      currentModule: 'punch_adjustment',
      title: 'Punch Adjustment',
      actions: [
        if (auth.canAdd('punch_adjustment'))
          isWide
              ? SriButton(
                  label: "Add Punch",
                  icon: Icons.add,
                  onPressed: () => controller.showForm(context, controller),
                )
              : IconButton(
                  onPressed: () => controller.showForm(context, controller),
                  icon: Icon(Icons.add),
                ),

        const SizedBox(width: 16.0),
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
            // ── Summary strip ──────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: AppColors.surface,
              child: Row(
                children: [
                  SummaryChip(
                    label: 'Total Adjustments',
                    value: rows.length,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  SummaryChip(
                    label: 'Employees',
                    value: manualLogs.map((l) => l.employeeId).toSet().length,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            // ── Table ─────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    TableHeader(),
                    ...rows.map(
                      (row) => TablesRow(
                        row: row,
                        canDelete: auth.canDelete('punch_adjustment'),
                        onDeleteIn: () {
                          final log = row['inLog'] as AttendanceLogModel?;
                          if (log != null) controller.deleteLog(log.id);
                        },
                        onDeleteOut: () {
                          final log = row['outLog'] as AttendanceLogModel?;
                          if (log != null) controller.deleteLog(log.id);
                        },
                        onEdit: auth.canEdit('punch_adjustment')
                            ? () => controller.showForm(
                                context,
                                controller,
                                prefillRow: row,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
