import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool disabled;
  final Color color;
  const PickerTile({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.disabled = false,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: disabled
            ? AppColors.surfaceVariant
            : selected
            ? color.withOpacity(0.06)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? color.withOpacity(0.5) : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: disabled
                ? AppColors.textMuted
                : selected
                ? color
                : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              disabled ? 'Pick From Time' : label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: disabled
                    ? AppColors.textMuted
                    : selected
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
