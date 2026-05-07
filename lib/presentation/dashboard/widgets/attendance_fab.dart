import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/routes/app_routes.dart';

class AttendanceFAB extends StatelessWidget {
  const AttendanceFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Get.toNamed(AppRoutes.routeFaceRecognition);
      },
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.fingerprint, color: Colors.white),
      label: const Text(
        'Mark Attendance',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}
