import 'dart:developer';

import 'package:get/get.dart';
import 'package:sri_hr/data/models/company_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/company/repository/company_repository.dart';
import 'package:sri_hr/presentation/helper/helper.dart';

AuthController get auth => Get.find<AuthController>();

class CompanyController extends GetxController {
  final repo = CompanyRepository();
  final company = Rxn<CompanyModel>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCompany();
  }

  Future<void> loadCompany() async {
    isLoading.value = true;
    try {
      company.value = await repo.getCompany(auth.companyId);
    } catch (e) {
      log("ERROR:$e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateCompany(
    Map<String, dynamic> data, {
    String? logoPath,
    List<int>? logoBytes,
  }) async {
    try {
      if (logoBytes != null && logoPath != null) {
        final url = await SupabaseService.uploadFile(
          'logos',
          logoPath,
          logoBytes,
        );
        data['logo_url'] = url;
      }
      company.value = await repo.updateCompany(auth.companyId, data);
      showSuccess('Company updated successfully');
    } catch (e) {
      showError('Failed to update company: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
