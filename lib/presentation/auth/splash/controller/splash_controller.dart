import 'package:get/get.dart';
import 'package:sri_hr/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashController extends GetxController {
  final supabase = Supabase.instance.client;

  @override
  void onReady() {
    super.onReady();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    Future.delayed(const Duration(seconds: 2), () {
      if (supabase.auth.currentSession == null) {
        Get.offAllNamed(AppRoutes.routeLogin);
      } else {
        Get.offAllNamed(AppRoutes.routeDashboard);
      }
    });
  }
}
