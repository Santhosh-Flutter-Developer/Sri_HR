import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class MiniPunchTag extends StatelessWidget {
  final String type, time;
  final Color color;
  final bool isManual;
  const MiniPunchTag(
    this.type,
    this.time,
    this.color,
    this.isManual, {
    super.key,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: 60,
    height: 60,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (isManual)
          const Text(
            'Manual',
            style: TextStyle(fontSize: 8, color: AppColors.warning),
          ),
      ],
    ),
  );
}
