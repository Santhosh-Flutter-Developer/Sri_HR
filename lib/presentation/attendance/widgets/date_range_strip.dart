import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';

class DateRangeStrip extends StatelessWidget {
  final AttendanceController controller;
  final VoidCallback onTap;
  const DateRangeStrip({
    super.key,
    required this.controller,
    required this.onTap,
  });

  String fmt(DateTime? d) {
    if (d == null) return '-';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(()=>InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: AppColors.primary.withOpacity(0.04),
        child: Row(
          children: [
            const Icon(
              Icons.date_range_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '${fmt(controller.fromDate.value)} – ${fmt(controller.toDate.value)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                dayRange(controller.fromDate.value, controller.toDate.value),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: controller.clearFilters,
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Reset', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                foregroundColor: AppColors.textMuted,
                minimumSize: Size.zero,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  String dayRange(DateTime? from, DateTime? to) {
    if (from == null || to == null) return '';
    final days = to.difference(from).inDays + 1;
    return '$days day${days != 1 ? 's' : ''}';
  }
}
