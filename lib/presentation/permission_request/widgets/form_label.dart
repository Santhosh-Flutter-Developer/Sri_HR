import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class FormLabel extends StatelessWidget {
  final String text;
  const FormLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
    ),
  );
}
