import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/subscription/widgets/toggle_btn.dart';

class DurationToggle extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;
  const DurationToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Choose Plan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ToggleBtn(
                label: 'Monthly',
                selected: selected == 'monthly',
                onTap: () => onChanged('monthly'),
              ),
              ToggleBtn(
                label: 'Yearly (Save 20%)',
                selected: selected == 'yearly',
                onTap: () => onChanged('yearly'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
