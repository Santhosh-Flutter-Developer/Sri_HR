import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/holiday/controller/holiday_controller.dart';
import 'package:sri_hr/presentation/holiday/widgets/holiday_card.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/empty_state.dart';
import 'package:sri_hr/widgets/loading_overlay.dart';
import 'package:sri_hr/widgets/sri_button.dart';

class Holiday extends StatelessWidget {
  Holiday({super.key});

  final controller = Get.isRegistered<HolidayController>()
      ? Get.find<HolidayController>()
      : Get.put(HolidayController());

  final auth = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return AppShell(
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
      child: Obx(
        () => controller.isLoading.value
            ? LoadingOverlay()
            : controller.holidays.isEmpty
            ? EmptyState(
                message:
                    'No holidays added for ${controller.selectedYear.value}',
                icon: Icons.celebration_outlined,
                actionLabel: auth.canAdd('holiday') ? 'Add Holiday' : null,
                onAction: () => controller.showForm(context, controller),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: controller.holidays.length,
                itemBuilder: (_, i) {
                  final h = controller.holidays[i];
                  return HolidayCard(
                    item: h,
                    onEdit: auth.canEdit('holiday')
                        ? () => controller.showForm(
                            context,
                            controller,
                            holiday: h,
                          )
                        : null,
                    onDelete: auth.canDelete('holiday')
                        ? () => controller.delete(h.id)
                        : null,
                  );
                },
              ),
      ),
    );
  }
}
