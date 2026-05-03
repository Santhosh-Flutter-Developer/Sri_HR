
import 'package:get/get.dart';
import 'package:sri_hr/presentation/company/controller/company_controller.dart';

class CompanyBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => CompanyController());
}
