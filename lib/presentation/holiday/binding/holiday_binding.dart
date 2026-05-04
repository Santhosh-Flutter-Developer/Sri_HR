import 'package:get/get.dart';
import 'package:sri_hr/presentation/company/controller/company_controller.dart';
import 'package:sri_hr/presentation/holiday/controller/holiday_controller.dart';

class HolidayBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HolidayController());
    Get.lazyPut(() => CompanyController());
  }
}
