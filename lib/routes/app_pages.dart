import 'package:get/get.dart';
import 'package:sri_hr/presentation/attendance/binding/attendance_binding.dart';
import 'package:sri_hr/presentation/attendance/ui/attendance.dart';
import 'package:sri_hr/presentation/attendance/ui/punch_time_adjustment.dart';
import 'package:sri_hr/presentation/auth/login/controller/login_controller.dart';
import 'package:sri_hr/presentation/auth/login/ui/login.dart';
import 'package:sri_hr/presentation/auth/middleware/auth_middleware.dart';
import 'package:sri_hr/presentation/auth/signup/ui/signup.dart';
import 'package:sri_hr/presentation/auth/splash/ui/splash.dart';
import 'package:sri_hr/presentation/company/binding/company_binding.dart';
import 'package:sri_hr/presentation/company/ui/company.dart';
import 'package:sri_hr/presentation/dashboard/binding/dashboard_binding.dart';
import 'package:sri_hr/presentation/dashboard/ui/dashboard.dart';
import 'package:sri_hr/presentation/department/binding/department_binding.dart';
import 'package:sri_hr/presentation/department/ui/department.dart';
import 'package:sri_hr/presentation/designation/binding/designation_binding.dart';
import 'package:sri_hr/presentation/designation/ui/designation.dart';
import 'package:sri_hr/presentation/employee/binding/employee_binding.dart';
import 'package:sri_hr/presentation/employee/ui/employee.dart';
import 'package:sri_hr/presentation/employee_status/binding/employee_status_binding.dart';
import 'package:sri_hr/presentation/employee_status/ui/employee_status.dart';
import 'package:sri_hr/presentation/face_capture/face_capture.dart';
import 'package:sri_hr/presentation/face_capture/face_recognition.dart';
import 'package:sri_hr/presentation/holiday/binding/holiday_binding.dart';
import 'package:sri_hr/presentation/holiday/ui/holiday.dart';
import 'package:sri_hr/presentation/leave/binding/leave_binding.dart';
import 'package:sri_hr/presentation/leave/ui/leave.dart';
import 'package:sri_hr/presentation/permission_request/binding/permission_binding.dart';
import 'package:sri_hr/presentation/permission_request/ui/permission_request.dart';
import 'package:sri_hr/presentation/salary_type/binding/salary_type_binding.dart';
import 'package:sri_hr/presentation/salary_type/ui/salary_type.dart';
import 'package:sri_hr/presentation/subscription/binding/subscription_binding.dart';
import 'package:sri_hr/presentation/subscription/middleware/subscription_middleware.dart';
import 'package:sri_hr/presentation/subscription/ui/subscription.dart';
import 'package:sri_hr/routes/app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.routeSplash, page: () => Splash()),
    GetPage(
      name: AppRoutes.routeLogin,
      page: () => Login(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => LoginController());
      }),
    ),
    GetPage(name: AppRoutes.routeSignup, page: () => Signup()),
    GetPage(
      name: AppRoutes.routeDashboard,
      page: () => Dashboard(),
      binding: DashboardBinding(),
      middlewares: [AuthMiddleware(), SubscriptionMiddleware()],
    ),
    GetPage(
      name: AppRoutes.routeDesignation,
      page: () => Designation(),
      binding: DesignationBinding(),
      middlewares: [AuthMiddleware(), SubscriptionMiddleware()],
    ),
    GetPage(
      name: AppRoutes.routeCompany,
      page: () => Company(),
      binding: CompanyBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.routeDepartment,
      page: () => Department(),
      binding: DepartmentBinding(),
      middlewares: [AuthMiddleware(), SubscriptionMiddleware()],
    ),
    GetPage(
      name: AppRoutes.routeEmployeeStatus,
      page: () => EmployeeStatus(),
      binding: EmployeeStatusBinding(),
      middlewares: [AuthMiddleware(), SubscriptionMiddleware()],
    ),
    GetPage(
      name: AppRoutes.routeSalaryType,
      page: () => SalaryType(),
      binding: SalaryTypeBinding(),
      middlewares: [AuthMiddleware(), SubscriptionMiddleware()],
    ),
    GetPage(
      name: AppRoutes.routeEmployee,
      page: () => Employee(),
      binding: EmployeeBinding(),
      middlewares: [AuthMiddleware(), SubscriptionMiddleware()],
    ),
    GetPage(
      name: AppRoutes.routeHoliday,
      page: () => Holiday(),
      binding: HolidayBinding(),
      middlewares: [AuthMiddleware(), SubscriptionMiddleware()],
    ),
    GetPage(
      name: AppRoutes.routeLeave,
      page: () => Leave(),
      binding: LeaveBinding(),
      middlewares: [AuthMiddleware(), SubscriptionMiddleware()],
    ),
    GetPage(
      name: AppRoutes.routePermission,
      page: () => PermissionRequest(),
      binding: PermissionBinding(),
      middlewares: [AuthMiddleware(), SubscriptionMiddleware()],
    ),
    GetPage(
      name: AppRoutes.routeAttendance,
      page: () => Attendance(),
      binding: AttendanceBinding(),
      middlewares: [AuthMiddleware(), SubscriptionMiddleware()],
    ),
    GetPage(
      name: AppRoutes.routePunchAdjustment,
      page: () => PunchTimeAdjustment(),
      binding: AttendanceBinding(),
      middlewares: [AuthMiddleware(), SubscriptionMiddleware()],
    ),
    GetPage(
      name: AppRoutes.routeSubscription,
      page: () => Subscription(),
      binding: SubscriptionBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(name: AppRoutes.routeFaceCapture, page: () => FaceCaptureView()),
    GetPage(
      name: AppRoutes.routeFaceRecognition,
      page: () => FaceRecognitionView(),
    ),
  ];
}
