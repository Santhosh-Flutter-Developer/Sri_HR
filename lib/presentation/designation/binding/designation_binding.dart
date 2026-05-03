import 'package:get/get.dart';
import 'package:sri_hr/presentation/company/controller/company_controller.dart';
import 'package:sri_hr/presentation/designation/controller/role_controller.dart';

class DesignationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RoleController());
    Get.lazyPut(() => CompanyController());
  }
}
