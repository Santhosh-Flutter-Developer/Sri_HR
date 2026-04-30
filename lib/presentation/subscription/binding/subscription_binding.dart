import 'package:get/get.dart';
import 'package:sri_hr/presentation/subscription/controller/subscription_controller.dart';

class SubscriptionBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => SubscriptionController());
}