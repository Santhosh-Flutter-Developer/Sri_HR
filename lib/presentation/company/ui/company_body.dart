import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/company/controller/company_controller.dart';
import 'package:sri_hr/presentation/company/ui/branch_list.dart';
import 'package:sri_hr/presentation/company/ui/company_detail.dart';

class CompanyBody extends StatelessWidget {
  final CompanyController controller;
  final AuthController auth;
  const CompanyBody({super.key, required this.controller, required this.auth});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return isWide ? wideLayout(context) : narrowLayout(context);
  }

  Widget wideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 300,
          child: BranchList(controller: controller, auth: auth),
        ),
        const VerticalDivider(width: 1, color: AppColors.border),
        Expanded(
          child: Obx(
            () => controller.activeCompany.value == null
                ? const Center(
                    child: Text(
                      'Select a branch to view details',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : CompanyDetail(
                    key: ValueKey(controller.activeCompany.value!.id),
                    company: controller.activeCompany.value!,
                    controller: controller,
                    canEdit: auth.canEdit('company'),
                  ),
          ),
        ),
      ],
    );
  }

  Widget narrowLayout(BuildContext context) {
    return Obx(
      () => controller.enable.value == false
          ? SingleChildScrollView(
              child: Column(
                children: [
                  BranchList(
                    controller: controller,
                    auth: auth,
                    onBranchTap: () {
                      controller.enable.value = true;
                      controller.enable.refresh();
                    },
                  ),
                  const Divider(height: 1.0, color: AppColors.border),
                ],
              ),
            )
          : Obx(
              () => controller.activeCompany.value == null
                  ? const SizedBox()
                  : CompanyDetail(
                      key: ValueKey(controller.activeCompany.value!.id),
                      company: controller.activeCompany.value!,
                      controller: controller,
                      canEdit: auth.canEdit('company'),
                    ),
            ),
    );
  }
}
