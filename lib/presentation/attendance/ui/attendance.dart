import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/attendance/ui/attendance_table.dart';
import 'package:sri_hr/presentation/attendance/widgets/filters_row.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/empty_state.dart';
import 'package:sri_hr/widgets/loading_overlay.dart';
import 'package:sri_hr/widgets/sri_button.dart';

class Attendance extends StatelessWidget {
  Attendance({super.key});

  final controller = Get.isRegistered<AttendanceController>()
      ? Get.find<AttendanceController>()
      : Get.put(AttendanceController());

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return AppShell(
      currentModule: 'attendance_report',
      title: 'Attendance Report',
      actions: [
        isWide
            ? SriButton(
                label: controller.formatDate(controller.selectedDate.value),
                icon: Icons.calendar_today_rounded,
                onPressed: () => controller.pickDate(context, controller),
              )
            : IconButton(
                onPressed: () => controller.pickDate(context, controller),
                icon: Icon(Icons.calendar_today_rounded),
              ),
        const SizedBox(width: 16.0),
      ],
      child: Obx(
        () => controller.isLoading.value
            ? const LoadingOverlay()
            : Column(
                children: [
                  FiltersRow(controller: controller),
                  Expanded(
                    child: controller.logs.isEmpty
                        ? const EmptyState(
                            message: 'No attendance records for this date',
                            icon: Icons.assessment_outlined,
                          )
                        : AttendanceTable(controller: controller),
                  ),
                ],
              ),
      ),
    );
  }
}
