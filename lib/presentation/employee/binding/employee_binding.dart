import 'package:get/get.dart';
import 'package:sri_hr/presentation/company/controller/company_controller.dart';
import 'package:sri_hr/presentation/department/controller/department_controller.dart';
import 'package:sri_hr/presentation/designation/controller/role_controller.dart';
import 'package:sri_hr/presentation/employee/controller/employee_controller.dart';
import 'package:sri_hr/presentation/employee_status/controller/employee_status_controller.dart';
import 'package:sri_hr/presentation/salary_type/controller/salary_type_controller.dart';


class EmployeeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EmployeeController());
    Get.lazyPut(() => DepartmentController());
    Get.lazyPut(() => RoleController());
    Get.lazyPut(() => EmployeeStatusController());
    Get.lazyPut(() => SalaryTypeController());
    Get.lazyPut(() => CompanyController());
  }
}