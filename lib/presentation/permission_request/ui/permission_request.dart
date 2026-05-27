import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/permission_request/controller/permission_request_controller.dart';
import 'package:sri_hr/presentation/permission_request/widgets/permission_request_card.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/empty_state.dart';
import 'package:sri_hr/widgets/filter_chip.dart';
import 'package:sri_hr/widgets/loading_overlay.dart';
import 'package:sri_hr/widgets/sri_button.dart';

class PermissionRequest extends StatelessWidget {
  PermissionRequest({super.key});

  final controller = Get.isRegistered<PermissionRequestController>()
      ? Get.find<PermissionRequestController>()
      : Get.put(PermissionRequestController());

  final auth = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return SafeArea(
      top: false,
      child: AppShell(
        currentModule: 'permission_request',
        title: 'Permission Requests',
        actions: [
          if (auth.canAdd('permission_request'))
            isWide
                ? SriButton(
                    label: "Add Request",
                    onPressed: () => controller.showForm(context, controller),
                    icon: Icons.add,
                  )
                : IconButton(
                    onPressed: () => controller.showForm(context, controller),
                    icon: Icon(Icons.add),
                  ),
        ],
        child: Column(
          children: [
            Obx(
              () => Padding(
                padding: EdgeInsets.only(
                  left: isWide ? 20.0 : 10.0,
                  right: isWide ? 20.0 : 10.0,
                  top: isWide ? 20.0 : 10.0,
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
                if (controller.isLoading.value) return const LoadingOverlay();
                if (controller.filteredPermission.isEmpty) {
                  return EmptyState(
                    message: 'No permission requests yet',
                    icon: Icons.timer_outlined,
                    actionLabel: auth.canAdd('permission_request')
                        ? 'Add Request'
                        : null,
                    onAction: () => controller.showForm(context, controller),
                  );
                }
                return RefreshIndicator(
                  onRefresh: controller.load,
                  child: ListView(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          top: isWide ? 24.0 : 10.0,
                          left: isWide ? 24.0 : 10.0,
                          right: isWide ? 24.0 : 10.0,
                          bottom: 10.0,
                        ),
                        child: ResponsiveGridRow(
                          children: List.generate(
                            controller.filteredPermission.length,
                            (i) {
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
                                  child: PermissionCard(
                                    req: controller.filteredPermission[i],
                                    canApprove: auth.canEdit(
                                      'permission_request',
                                    ),
                                    canDelete: auth.canDelete(
                                      'permission_request',
                                    ),
                                    onApprove: () => controller.approve(
                                      controller.filteredPermission[i].id,
                                    ),
                                    onReject: () => controller.reject(
                                      controller.filteredPermission[i].id,
                                    ),
                                    onDelete: () => controller.confirmDelete(
                                      context,
                                      controller.filteredPermission[i].id,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
