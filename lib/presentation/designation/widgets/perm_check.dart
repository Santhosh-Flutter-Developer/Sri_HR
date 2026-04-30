import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class PermCheck extends StatelessWidget {
  final bool value;
  final VoidCallback onChanged;
  const PermCheck({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: value ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value ? AppColors.primary : AppColors.border,
            width: 2,
          ),
        ),
        child: value
            ? const Icon(Icons.check, color: Colors.white, size: 14)
            : null,
      ),
    );
  }
}
