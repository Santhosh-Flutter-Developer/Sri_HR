import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/auth/signup/controller/signup_controller.dart';

class Signup extends StatelessWidget {
  Signup({super.key});

  final controller = Get.isRegistered<SignupController>()
      ? Get.find<SignupController>()
      : Get.put(SignupController());

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: isWide ? null : AppBar(title: const Text("Register Company")),
      body: isWide ? controller.wideLayout() : controller.narrowLayout(),
    );
  }
}
