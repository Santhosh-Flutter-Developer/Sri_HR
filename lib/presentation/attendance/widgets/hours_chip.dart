import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class HoursChip extends StatelessWidget {
  final double hours;
  const HoursChip({super.key, required this.hours});

  @override
  Widget build(BuildContext context) {
    final isOk = hours >= 8;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOk
            ? AppColors.success.withOpacity(0.1)
            : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${hours}h',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isOk ? AppColors.success : AppColors.warning,
        ),
      ),
    );
  }
}
