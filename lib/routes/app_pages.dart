import 'package:get/get.dart';
import 'package:sri_hr/presentation/auth/login/ui/login.dart';
import 'package:sri_hr/presentation/auth/signup/ui/signup.dart';
import 'package:sri_hr/routes/app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.routeLogin,
      page: () => Login(),
    ),
    GetPage(
      name: AppRoutes.routeSignup,
      page: () => const Signup(),
    ),
  ];
}
