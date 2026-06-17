import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';

class PaginationBar extends StatelessWidget {
  final AttendanceController controller;
  const PaginationBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return Obx(() {
      final total = controller.filteredRows.length;
      final page = controller.currentPage.value;
      final size = controller.pageSize.value;
      final totalPages = controller.totalPages;
      final start = total == 0 ? 0 : page * size + 1;
      final end = (page * size + size).clamp(0, total);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            // Rows per page selector
            if (isWide)
              Row(
                children: [
                  const Text(
                    'Rows per page:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: size,
                        isDense: true,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        items: controller.pageSizeOptions
                            .map(
                              (v) =>
                                  DropdownMenuItem(value: v, child: Text('$v')),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) controller.setPageSize(v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            if (isWide) const Spacer(),

            // Record range info
            Text(
              total == 0 ? '0 records' : '$start–$end of $total',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!isWide) Spacer(),
            const SizedBox(width: 12),

            // Prev button
            _NavBtn(
              icon: Icons.chevron_left_rounded,
              enabled: page > 0,
              onTap: () => controller.goToPage(page - 1),
            ),

            const SizedBox(width: 4),

            // Page indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Text(
                '${page + 1} / $totalPages',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(width: 4),

            // Next button
            _NavBtn(
              icon: Icons.chevron_right_rounded,
              enabled: page < totalPages - 1,
              onTap: () => controller.goToPage(page + 1),
            ),
          ],
        ),
      );
    });
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _NavBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.surfaceVariant
              : AppColors.border.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? AppColors.border
                : AppColors.border.withOpacity(0.4),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ),
    );
  }
}
