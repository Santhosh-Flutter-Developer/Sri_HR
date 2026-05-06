import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class PunchCell extends StatelessWidget {
  final String time, type;
  final bool exists, isManual, canDelete;
  final VoidCallback onDelete;
  const PunchCell({
    super.key,
    required this.time,
    required this.type,
    required this.exists,
    required this.isManual,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (!exists) {
      return const Text('—', style: TextStyle(color: AppColors.textMuted));
    }
    final color = type == 'IN' ? AppColors.success : AppColors.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type == 'IN' ? Icons.login_rounded : Icons.logout_rounded,
                size: 11,
                color: color,
              ),
              const SizedBox(width: 3),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (isManual) ...[
                const SizedBox(width: 3),
                const Text(
                  'M',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (canDelete) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close_rounded,
              size: 13,
              color: AppColors.error.withOpacity(0.7),
            ),
          ),
        ],
      ],
    );
  }
}
