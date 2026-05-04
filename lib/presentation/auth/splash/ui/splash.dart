import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/auth/splash/controller/splash_controller.dart';
import 'package:sri_hr/widgets/app_linear_progress_indicator.dart';

class Splash extends StatelessWidget {
  Splash({super.key});

  final controller = Get.isRegistered<SplashController>()
      ? Get.find<SplashController>()
      : Get.put(SplashController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: AppColors.surface,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Hero(
                tag: "main_logo",
                child: Image.asset(
                  "assets/images/gif/ic_logo.gif",
                  width: MediaQuery.of(context).size.width * .8,
                ),
              ),
            ),
            const AppLinearProgressIndicator(
              width: 60,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
