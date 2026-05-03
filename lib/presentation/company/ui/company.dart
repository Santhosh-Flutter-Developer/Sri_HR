import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/company/controller/company_controller.dart';
import 'package:sri_hr/presentation/company/ui/company_body.dart';
import 'package:sri_hr/presentation/company/widgets/error_widget.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/loading_overlay.dart';
import 'package:sri_hr/widgets/sri_button.dart';

class Company extends StatelessWidget {
  Company({super.key});

  final controller = Get.isRegistered<CompanyController>()
      ? Get.find<CompanyController>()
      : Get.put(CompanyController());

  final auth = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return AppShell(
      currentModule: 'company',
      title: 'Company Settings',
      actions: [
        if (auth.canAdd('company'))
          isWide
              ? SriButton(
                  label: 'Add Branch',
                  icon: Icons.add_business_rounded,
                  onPressed: () =>
                      controller.showAddBranchDialog(context, controller),
                )
              : IconButton(
                  onPressed: () =>
                      controller.showAddBranchDialog(context, controller),
                  icon: Icon(Icons.add_business_rounded),
                ),
        const SizedBox(width: 16.0),
      ],
      child: Obx(() {
        if (controller.isLoading.value && controller.companies.isEmpty) {
          return const LoadingOverlay();
        }
        if (controller.errorMessage.value.isNotEmpty &&
            controller.companies.isEmpty) {
          return ErrorrWidget(
            message: controller.errorMessage.value,
            onRetry: controller.loadAllCompanies,
          );
        }
        return CompanyBody(controller: controller, auth: auth);
      }),
    );
  }
}
