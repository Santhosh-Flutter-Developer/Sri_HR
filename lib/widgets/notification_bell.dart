import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/notifications/controller/notification_controller.dart';
import 'package:sri_hr/routes/app_routes.dart';

/// Bell icon with unread badge. Tap → Notifications page.
class NotificationBell extends StatelessWidget {
  final Color? color;
  const NotificationBell({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NotificationController>()) {
      return const SizedBox.shrink();
    }
    final c = Get.find<NotificationController>();
    return Obx(() {
      final n = c.unreadCount;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: 'Notifications',
            icon: Icon(
              n > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: color ?? AppColors.textSecondary,
              size: 24,
            ),
            onPressed: () {
              if (Get.currentRoute != AppRoutes.routeNotifications) {
                Get.toNamed(AppRoutes.routeNotifications);
              }
            },
          ),
          if (n > 0)
            Positioned(
              right: 4,
              top: 4,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    n > 99 ? '99+' : '$n',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}