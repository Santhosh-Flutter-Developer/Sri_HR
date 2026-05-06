import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class PickerBox extends StatelessWidget {
  final IconData icon;
  final String label, trailingLabel;
  final bool selected;
  final Color color;
  const PickerBox({
    super.key,
    required this.icon,
    required this.label,
    required this.trailingLabel,
    required this.selected,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: selected ? color.withOpacity(0.5) : AppColors.border,
      ),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: selected ? color : AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: selected ? AppColors.textPrimary : AppColors.textMuted,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          trailingLabel,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    ),
  );
}
