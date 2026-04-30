import 'package:get/get.dart';
import 'package:sri_hr/presentation/department/controller/department_controller.dart';

class DepartmentBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => DepartmentController());
}
