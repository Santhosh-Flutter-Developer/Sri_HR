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
                  label: 'Add Request',
                  icon: Icons.add,
                  onPressed: () => controller.showForm(context, controller),
                )
              : IconButton(
                  onPressed: () => controller.showForm(context, controller),
                  icon: Icon(Icons.add),
                ),
        const SizedBox(width: 16.0),
      ],
      child: Obx(
        () => controller.isLoading.value
            ? const LoadingOverlay()
            : controller.permission.isEmpty
            ? const EmptyState(
                message: 'No permission requests',
                icon: Icons.timer_outlined,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: controller.permission.length,
                itemBuilder: (_, i) {
                  final req = controller.permission[i];
                  return PermissionRequestCard(
                    req: req,
                    controller: controller,
                  );
                },
              ),
      ),
    );
  }
}
