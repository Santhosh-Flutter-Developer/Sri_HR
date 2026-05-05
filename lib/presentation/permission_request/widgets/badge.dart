import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class Badgee extends StatelessWidget {
  final String label;
  final Color color;
  final bool border;
  const Badgee(this.label, this.color, {super.key, this.border = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: border ? Colors.transparent : color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: border ? Border.all(color: AppColors.border) : null,
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
    ),
  );
}
