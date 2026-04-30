import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class MiniChip extends StatelessWidget {
  final String label;
  final bool active;
  const MiniChip({super.key, required this.label, required this.active});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: active
                ? AppColors.success.withOpacity(0.1)
                : AppColors.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(4)),
        child: Text(label,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.success : AppColors.error)),
      );
}