import 'package:get/get.dart';
import 'package:sri_hr/presentation/designation/controller/role_controller.dart';

class DesignationBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => RoleController());
}
