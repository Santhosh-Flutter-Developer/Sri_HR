import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status.toLowerCase()) {
      'approved' ||
      'active' ||
      'paid' => (const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
      'rejected' ||
      'expired' => (const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
      'pending' => (const Color(0xFFD97706), const Color(0xFFFEF3C7)),
      _ => (AppColors.textSecondary, AppColors.border),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
