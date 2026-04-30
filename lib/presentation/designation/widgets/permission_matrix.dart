import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/designation/controller/role_controller.dart';
import 'package:sri_hr/presentation/designation/widgets/perm_check.dart';

class PermissionMatrix extends StatelessWidget {
  final RoleController ctrl;
  const PermissionMatrix({super.key, required this.ctrl});

  static const _moduleLabels = {
    'dashboard': 'Dashboard',
    'designation': 'Designation',
    'company': 'Company',
    'department': 'Department',
    'employee_status': 'Employee Status',
    'salary_type': 'Salary Type',
    'employee': 'Employee',
    'holiday': 'Holiday Entry',
    'leave_request': 'Leave Request',
    'permission_request': 'Permission Request',
    'attendance_report': 'Attendance Report',
    'punch_adjustment': 'Punch Adjustment',
    'subscription': 'Subscription',
  };

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return Container(
      margin: isWide
          ? EdgeInsets.fromLTRB(0, 24, 24, 24)
          : EdgeInsets.fromLTRB(0, 24, 0, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                if (!isWide)
                  IconButton(
                    onPressed: () {
                      ctrl.enable.value = false;
                    },
                    icon: Icon(Icons.keyboard_arrow_left, color: AppColors.bg),
                  ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.security_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Obx(
                  () => Text(
                    'Permissions – ${ctrl.selectedRole.value?.name ?? ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: ctrl.savePermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surfaceVariant,
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Module',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'View',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rows
          Expanded(
            child: Obx(
              () => ListView.separated(
                itemCount: ctrl.editingPermissions.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.border),
                itemBuilder: (_, i) {
                  final p = ctrl.editingPermissions[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            _moduleLabels[p.module] ?? p.module,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: PermCheck(
                              value: p.canView,
                              onChanged: () => ctrl.togglePermission(i, 'view'),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: PermCheck(
                              value: p.canAdd,
                              onChanged: () => ctrl.togglePermission(i, 'add'),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: PermCheck(
                              value: p.canEdit,
                              onChanged: () => ctrl.togglePermission(i, 'edit'),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: PermCheck(
                              value: p.canDelete,
                              onChanged: () =>
                                  ctrl.togglePermission(i, 'delete'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
