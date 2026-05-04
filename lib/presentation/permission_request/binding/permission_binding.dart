import 'package:get/get.dart';
import 'package:sri_hr/presentation/company/controller/company_controller.dart';
import 'package:sri_hr/presentation/employee/controller/employee_controller.dart';
import 'package:sri_hr/presentation/permission_request/controller/permission_request_controller.dart';

class PermissionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PermissionRequestController());
    Get.lazyPut(() => EmployeeController());
    Get.lazyPut(() => CompanyController());
  }
}
