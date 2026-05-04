import 'package:get/get.dart';
import 'package:sri_hr/presentation/company/controller/company_controller.dart';
import 'package:sri_hr/presentation/department/controller/department_controller.dart';
import 'package:sri_hr/presentation/designation/controller/role_controller.dart';
import 'package:sri_hr/presentation/employee/controller/employee_controller.dart';
import 'package:sri_hr/presentation/leave/controller/leave_controller.dart';

class LeaveBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LeaveController());
    Get.lazyPut(() => EmployeeController());
    Get.lazyPut(() => DepartmentController());
    Get.lazyPut(() => RoleController());
    Get.lazyPut(() => CompanyController());
  }
}
