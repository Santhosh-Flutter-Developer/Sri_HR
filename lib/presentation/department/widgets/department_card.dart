import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/department_model.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/department/controller/department_controller.dart';
import 'package:sri_hr/presentation/department/widgets/mini_chip.dart';

class DepartmentCard extends StatelessWidget {
  final DepartmentModel item;
  DepartmentCard({super.key, required this.item});
  final controller = Get.isRegistered<DepartmentController>()
      ? Get.find<DepartmentController>()
      : Get.put(DepartmentController());
  final auth = Get.find<AuthController>();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_tree_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Code: ${item.code}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    MiniChip(
                      label: 'Mobile: ${item.mobileLogin ? 'Yes' : 'No'}',
                      active: item.mobileLogin,
                    ),
                    const SizedBox(width: 6),
                    MiniChip(
                      label:
                          'Outside: ${item.outsideAttendance ? 'Yes' : 'No'}',
                      active: item.outsideAttendance,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (auth.canEdit('department'))
                GestureDetector(
                  onTap: () =>
                      controller.showForm(context, controller, dept: item),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              if (auth.canDelete('department')) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => controller.delete(item.id),
                  child: const Icon(
                    Icons.delete_rounded,
                    size: 16,
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
