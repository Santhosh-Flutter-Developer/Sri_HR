import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/routes/app_routes.dart';

class SubscriptionMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Allow subscription page always
    if (route == AppRoutes.routeSubscription ||
        route == AppRoutes.routeCompany) {
      return null;
    }

    // Check subscription
    try {
      final authCtrl = Get.find<AuthController>(tag: 'auth');
      if (!authCtrl.isSubscriptionActive.value) {
        return const RouteSettings(name: AppRoutes.routeSubscription);
      }
    } catch (_) {
      // Controller not ready yet
    }
    return null;
  }
}
