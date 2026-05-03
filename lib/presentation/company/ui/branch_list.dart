import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/company/controller/company_controller.dart';
import 'package:sri_hr/presentation/company/ui/branch_tile.dart';

class BranchList extends StatelessWidget {
  final CompanyController controller;
  final AuthController auth;
  final VoidCallback? onBranchTap;
  const BranchList({
    super.key,
    required this.controller,
    required this.auth,
    this.onBranchTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return Container(
      color: AppColors.surfaceVariant,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: AppColors.surface,
            child: Row(
              children: [
                const Icon(
                  Icons.corporate_fare_rounded,
                  color: AppColors.primary,
                  size: 18.0,
                ),
                const SizedBox(width: 8.0),
                const Text(
                  "All Branches",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.0,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 3.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      '${controller.companies.length}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1.0, color: AppColors.border),
          isWide
              ? Expanded(
                  child: Obx(
                    () => ListView.separated(
                      itemBuilder: (_, i) {
                        final c = controller.companies[i];
                        final isActive =
                            controller.activeCompany.value?.id == c.id;
                        return BranchTile(
                          company: c,
                          isActive: isActive,
                          controller: controller,
                          onTap: () {
                            controller.activeCompany.value = c;
                            if (!isActive) {
                              controller.confirmSwitch(context, controller, c);
                            }
                            onBranchTap?.call();
                          },
                          onDelete:
                              auth.canDelete('company') &&
                                  controller.companies.length > 1
                              ? () => controller.confirmDelete(
                                  context,
                                  controller,
                                  c,
                                )
                              : null,
                        );
                      },
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1.0, color: AppColors.border),
                      itemCount: controller.companies.length,
                    ),
                  ),
                )
              : SizedBox(
                  height: 200,
                  child: Obx(
                    () => ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (_, i) {
                        final c = controller.companies[i];
                        final isActive =
                            controller.activeCompany.value?.id == c.id;
                        return BranchTile(
                          company: c,
                          isActive: isActive,
                          controller: controller,
                          onTap: () {
                            controller.activeCompany.value = c;
                            if (!isActive) {
                              controller.confirmSwitch(context, controller, c);
                            }
                            onBranchTap?.call();
                          },
                          onDelete:
                              auth.canDelete('company') &&
                                  controller.companies.length > 1
                              ? () => controller.confirmDelete(
                                  context,
                                  controller,
                                  c,
                                )
                              : null,
                        );
                      },
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1.0, color: AppColors.border),
                      itemCount: controller.companies.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
