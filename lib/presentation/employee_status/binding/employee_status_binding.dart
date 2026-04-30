import 'package:get/get.dart';
import 'package:sri_hr/presentation/employee_status/controller/employee_status_controller.dart';

class EmployeeStatusBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => EmployeeStatusController());
}
