import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/leave/controller/leave_controller.dart';
import 'package:sri_hr/widgets/filter_chip.dart';
import 'package:sri_hr/presentation/leave/widgets/leave_card.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/empty_state.dart';
import 'package:sri_hr/widgets/loading_overlay.dart';
import 'package:sri_hr/widgets/sri_button.dart';

class Leave extends StatelessWidget {
  Leave({super.key});
  final controller = Get.isRegistered<LeaveController>()
      ? Get.find<LeaveController>()
      : Get.put(LeaveController());
  final auth = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return AppShell(
      currentModule: 'leave_request',
      title: 'Leave Requests',
      actions: [
        // Filter chips
        // Obx(
        //   () => Row(
        //     children: [
        //       FilterChips(
        //         label: 'All',
        //         selected: controller.filterStatus.value == null,
        //         onTap: () => controller.filterStatus.value = null,
        //       ),
        //       const SizedBox(width: 6),
        //       FilterChips(
        //         label: 'Pending',
        //         color: AppColors.warning,
        //         selected: controller.filterStatus.value == 'pending',
        //         onTap: () => controller.filterStatus.value = 'pending',
        //       ),
        //       const SizedBox(width: 6),
        //       FilterChips(
        //         label: 'Approved',
        //         color: AppColors.success,
        //         selected: controller.filterStatus.value == 'approved',
        //         onTap: () => controller.filterStatus.value = 'approved',
        //       ),
        //       const SizedBox(width: 6),
        //       FilterChips(
        //         label: 'Rejected',
        //         color: AppColors.error,
        //         selected: controller.filterStatus.value == 'rejected',
        //         onTap: () => controller.filterStatus.value = 'rejected',
        //       ),
        //     ],
        //   ),
        // ),
        // const SizedBox(width: 12),
        if (auth.canAdd('leave_request'))
          isWide
              ? SriButton(
                  label: "Add Leave",
                  icon: Icons.add,
                  onPressed: () =>
                      controller.openLeaveForm(context, controller),
                )
              : IconButton(
                  onPressed: () =>
                      controller.openLeaveForm(context, controller),
                  icon: Icon(Icons.add),
                ),
        const SizedBox(width: 16),
      ],
      child: Column(
        children: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 20.0,
              ),
              child: Row(
                children: [
                  FilterChips(
                    label: 'All',
                    selected: controller.filterStatus.value == null,
                    onTap: () => controller.filterStatus.value = null,
                  ),
                  const SizedBox(width: 6),
                  FilterChips(
                    label: 'Pending',
                    color: AppColors.warning,
                    selected: controller.filterStatus.value == 'pending',
                    onTap: () => controller.filterStatus.value = 'pending',
                  ),
                  const SizedBox(width: 6),
                  FilterChips(
                    label: 'Approved',
                    color: AppColors.success,
                    selected: controller.filterStatus.value == 'approved',
                    onTap: () => controller.filterStatus.value = 'approved',
                  ),
                  const SizedBox(width: 6),
                  FilterChips(
                    label: 'Rejected',
                    color: AppColors.error,
                    selected: controller.filterStatus.value == 'rejected',
                    onTap: () => controller.filterStatus.value = 'rejected',
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const LoadingOverlay();
              }
              final leaves = controller.filteredLeaves;
              if (leaves.isEmpty) {
                return EmptyState(
                  message: 'No Leave requests found',
                  icon: Icons.event_busy_outlined,
                  actionLabel: auth.canAdd('leave_request')
                      ? "Add Leave"
                      : null,
                  onAction: () => controller.openLeaveForm(context, controller),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.loadLeaves,
                child: ListView.builder(
                  padding: const EdgeInsets.all(20.0),
                  itemCount: leaves.length,
                  itemBuilder: (_, i) => LeaveCard(
                    leave: leaves[i],
                    canApprove: auth.canEdit('leave_request'),
                    canDelete: auth.canDelete('leave_request'),
                    onApprove: () => controller.approve(leaves[i].id),
                    onReject: () => controller.reject(leaves[i].id),
                    onDelete: () => controller.confirmDelete(
                      context,
                      controller,
                      leaves[i].id,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
