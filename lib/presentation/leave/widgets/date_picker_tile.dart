import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final String displayDate;
  final VoidCallback onTap;
  final bool isSelected;
  final bool disabled;

  const DatePickerTile({super.key, 
    required this.label,
    required this.date,
    required this.displayDate,
    required this.onTap,
    this.isSelected = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.border.withOpacity(0.3)
              : isSelected
                  ? AppColors.primary.withOpacity(0.06)
                  : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.5)
                : disabled
                    ? AppColors.border.withOpacity(0.3)
                    : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: disabled
                      ? AppColors.textMuted
                      : AppColors.textSecondary)),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.calendar_today_rounded,
                size: 14,
                color: isSelected
                    ? AppColors.primary
                    : disabled
                        ? AppColors.border
                        : AppColors.textMuted),
            const SizedBox(width: 6),
            Flexible(
                child: Text(
              disabled ? 'Pick from first' : displayDate,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? AppColors.textPrimary
                    : disabled
                        ? AppColors.textMuted
                        : AppColors.textMuted,
              ),
              overflow: TextOverflow.ellipsis,
            )),
          ]),
        ]),
      ),
    );
  }
}