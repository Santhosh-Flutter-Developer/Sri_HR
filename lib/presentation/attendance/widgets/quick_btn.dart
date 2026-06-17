import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class QuickBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const QuickBtn(this.label, this.onTap, {super.key, this.isSelected = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.2),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected) ...[
            const Icon(Icons.check_rounded, size: 12, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
          ),
        ],
      ),
    ),
  );
}