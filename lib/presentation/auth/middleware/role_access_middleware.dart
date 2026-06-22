import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/routes/app_routes.dart';

/// Maps a route name to its permission module key.
/// Routes not in this map are freely accessible (e.g. splash, login, kiosk).
const _routeModuleMap = {
  AppRoutes.routeDashboard: 'dashboard',
  AppRoutes.routeDesignation: 'designation',
  AppRoutes.routeCompany: 'company',
  AppRoutes.routeDepartment: 'department',
  AppRoutes.routeEmployeeStatus: 'employee_status',
  AppRoutes.routeSalaryType: 'salary_type',
  AppRoutes.routeEmployee: 'employee',
  AppRoutes.routeHoliday: 'holiday',
  AppRoutes.routeLeave: 'leave_request',
  AppRoutes.routePermission: 'permission_request',
  AppRoutes.routeAttendance: 'attendance_report',
  AppRoutes.routePunchAdjustment: 'punch_adjustment',
  AppRoutes.routeSubscription: 'subscription',
};

class RoleAccessMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (route == null) return null;

    final module = _routeModuleMap[route];
    if (module == null) return null; // unguarded route — allow

    // AuthController must already be registered by this point
    // (AuthMiddleware runs first and ensures the user is logged in).
    final auth = Get.find<AuthController>();

    if (!auth.canView(module)) {
      // Redirect to dashboard if they can see it, else subscription page
      final fallback = auth.canView('dashboard')
          ? AppRoutes.routeDashboard
          : AppRoutes.routeSubscription;
      return RouteSettings(name: fallback);
    }

    return null; // access granted
  }
}