import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class AttendanceFAB extends StatelessWidget {
  const AttendanceFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {},
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.fingerprint, color: Colors.white),
      label: const Text(
        'Mark Attendance',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}
