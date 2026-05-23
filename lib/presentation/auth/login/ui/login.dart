import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/auth/login/controller/login_controller.dart';

class Login extends GetView<LoginController> {
  const Login({super.key});
  
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.sidebarBg,
        statusBarIconBrightness: Brightness.light,
      ),
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: AppColors.bg,
          body: isWide ? controller.wideLayout() : controller.narrowLayout(),
        ),
      ),
    );
  }
}
