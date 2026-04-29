import 'package:get/get.dart';
import 'package:sri_hr/presentation/auth/login/ui/login.dart';
import 'package:sri_hr/presentation/auth/middleware/auth_middleware.dart';
import 'package:sri_hr/presentation/auth/signup/ui/signup.dart';
import 'package:sri_hr/presentation/dashboard/binding/dashboard_binding.dart';
import 'package:sri_hr/presentation/dashboard/ui/dashboard.dart';
import 'package:sri_hr/presentation/subscription/middleware/subscription_middleware.dart';
import 'package:sri_hr/routes/app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.routeLogin, page: () => Login()),
    GetPage(name: AppRoutes.routeSignup, page: () => Signup()),
    GetPage(
      name: AppRoutes.routeDashboard,
      page: () => Dashboard(),
      binding: DashboardBinding(),
      middlewares: [AuthMiddleware(), SubscriptionMiddleware()],
    ),
  ];
}
