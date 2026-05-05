import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/permission_request/controller/permission_request_controller.dart';
import 'package:sri_hr/presentation/permission_request/widgets/permission_request_card.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/empty_state.dart';
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
    return AppShell(
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
        const SizedBox(width: 16),
      ],
      child: Obx(() {
        if (controller.isLoading.value) return const LoadingOverlay();
        if (controller.permission.isEmpty) {
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
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: controller.permission.length,
            itemBuilder: (_, i) => PermissionCard(
              req: controller.permission[i],
              canApprove: auth.canEdit('permission_request'),
              canDelete: auth.canDelete('permission_request'),
              onApprove: () => controller.approve(controller.permission[i].id),
              onReject: () => controller.reject(controller.permission[i].id),
              onDelete: () => controller.delete(controller.permission[i].id),
            ),
          ),
        );
      }),
    );
  }
}
