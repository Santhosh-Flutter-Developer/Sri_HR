import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/designation/controller/role_controller.dart';
import 'package:sri_hr/presentation/designation/ui/role_form.dart';
import 'package:sri_hr/presentation/designation/widgets/permission_matrix.dart';
import 'package:sri_hr/presentation/designation/widgets/role_card.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/empty_state.dart';
import 'package:sri_hr/widgets/loading_overlay.dart';
import 'package:sri_hr/widgets/sri_button.dart';
import 'package:sri_hr/widgets/sri_search_bar.dart';

class Designation extends StatelessWidget {
  Designation({super.key});

  final controller = Get.isRegistered<RoleController>()
      ? Get.find<RoleController>()
      : Get.put(RoleController());

  final auth = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return AppShell(
      currentModule: 'designation',
      title: "Designations",
      actions: [
        if (auth.canAdd('designation'))
          isWide
              ? SriButton(
                  icon: Icons.add,
                  onPressed: () => showRoleForm(context, controller),
                  label: "Add Designation",
                )
              : IconButton(
                  onPressed: () => showRoleForm(context, controller),
                  icon: Icon(Icons.add),
                ),
      ],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: searchWidget(context)),
              if (isWide)
                Padding(
                  padding: const EdgeInsets.only(
                    right: 8.0,
                    top: 10.0,
                    // bottom: 20.0,
                  ),
                  child: IconButton(
                    onPressed: controller.loadRoles,
                    icon: Icon(Icons.refresh, color: AppColors.primary),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Obx(
              () => controller.isLoading.value
                  ? const LoadingOverlay()
                  : controller.filteredroles.isEmpty
                  ? EmptyState(
                      message: 'No designations created yet',
                      icon: Icons.badge_outlined,
                      actionLabel: auth.canAdd('designation')
                          ? 'Add Designation'
                          : null,
                      onAction: () => showRoleForm(context, controller),
                    )
                  : RefreshIndicator(
                      onRefresh: controller.loadRoles,
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left: list
                                Flexible(
                                  flex: 2,
                                  child: designationList(context),
                                ),
                                // Right: permissions panel
                                Flexible(
                                  flex: 3,
                                  child: designationPermission(),
                                ),
                              ],
                            )
                          : controller.enable.value
                          ? designationPermission()
                          : designationList(context),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget searchWidget(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return Padding(
      padding: EdgeInsets.only(
        top: isWide ? 24.0 : 10.0,
        left: isWide ? 24.0 : 10.0,
        right: 10.0,
        bottom: 10.0,
      ),
      child: SriSearchBar(
        label: "Search Designations",
        prefixIcon: Icons.search,
        onChanged: controller.search,
      ),
    );
  }

  Widget designationList(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return ListView.builder(
      padding: EdgeInsets.only(
        top: 10.0,
        left: isWide ? 24.0 : 10.0,
        right: isWide ? 24.0 : 10.0,
        bottom: 10.0,
      ),
      itemCount: controller.filteredroles.length,
      itemBuilder: (_, i) => Obx(
        () => RoleCard(
          role: controller.filteredroles[i],
          isSelected:
              controller.selectedRole.value?.id ==
              controller.filteredroles[i].id,
          onTap: () {
            controller.enable.value = true;
            controller.selectRole(controller.filteredroles[i]);
          },
          onEdit: auth.canEdit('designation')
              ? () => showRoleForm(
                  context,
                  controller,
                  role: controller.filteredroles[i],
                )
              : null,
          onDelete: auth.canDelete('designation')
              ? () => confirmDelete(
                  context,
                  controller,
                  controller.filteredroles[i].id,
                )
              : null,
        ),
      ),
    );
  }

  Widget designationPermission() {
    return Obx(
      () => controller.selectedRole.value == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Select a designation to manage permissions',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ],
              ),
            )
          : PermissionMatrix(ctrl: controller),
    );
  }

  void showRoleForm(BuildContext context, RoleController ctrl, {dynamic role}) {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.all(4.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: RoleForm(role: role, controller: ctrl),
      ),
      barrierDismissible: false,
    );
  }

  void confirmDelete(BuildContext context, RoleController ctrl, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Designation'),
        content: const Text(
          'Are you sure? Employees with this designation may be affected.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ctrl.deleteRole(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
