import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class SriTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool enabled;
  final void Function(String)? onChanged;
  final IconData? suffixIcon;
  final Widget? suffixIconWidget;
  final VoidCallback? onSuffixTap;

  const SriTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.suffixIcon,
    this.onSuffixTap,
    this.suffixIconWidget,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: AppColors.textMuted)
            : null,
        suffixIcon:suffixIconWidget ?? (suffixIcon != null
            ? GestureDetector(
                onTap: onSuffixTap,
                child: Icon(suffixIcon, size: 20, color: AppColors.textMuted),
              )
            : null),
      ),
    );
  }
}
