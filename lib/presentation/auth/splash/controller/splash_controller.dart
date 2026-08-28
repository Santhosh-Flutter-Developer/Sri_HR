import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sri_hr/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashController extends GetxController {
  final supabase = Supabase.instance.client;
  final _box = GetStorage();

  @override
  void onReady() {
    super.onReady();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    // ── 1. Check persisted kiosk session first ──────────────
    final kioskCompanyId = _box.read<String>('kiosk_company_id');
    if (kioskCompanyId != null && kioskCompanyId.isNotEmpty) {
      Get.offAllNamed(
        AppRoutes.routeKioskAttendance,
        arguments: {'company_id': kioskCompanyId},
      );
      return;
    }

    // ── 2. Check normal Supabase session ────────────────────
    if (supabase.auth.currentSession == null) {
      Get.offAllNamed(AppRoutes.routeLogin);
    } else {
      Get.offAllNamed(AppRoutes.routeDashboard);
    }
  }
}
