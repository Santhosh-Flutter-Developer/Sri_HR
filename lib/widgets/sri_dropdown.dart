import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class SriDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String label;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final IconData? prefixIcon;

  const SriDropdown({
    super.key,
    this.value,
    required this.items,
    required this.label,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: AppColors.textMuted)
            : null,
      ),
      dropdownColor: AppColors.surface,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
        fontFamily: 'Nunito',
      ),
    );
  }
}
