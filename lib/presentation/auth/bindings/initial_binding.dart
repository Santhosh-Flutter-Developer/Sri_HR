import 'package:get/get.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/notifications/controller/notification_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<NotificationController>(NotificationController(), permanent: true);
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}