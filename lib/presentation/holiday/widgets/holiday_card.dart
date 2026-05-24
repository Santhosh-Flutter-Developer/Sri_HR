import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/holiday_model.dart';

class HolidayCard extends StatelessWidget {
  final HolidayModel item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const HolidayCard({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${item.date.day}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.accent,
                  ),
                ),
                Text(
                  _monthShort(item.date.month),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.reason,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${item.days} day${item.days > 1 ? 's' : ''}  •  ${item.date.year}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null || onDelete != null)
            PopupMenuButton(
              itemBuilder: (_) => [
                if (onEdit != null)
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
              ],
              onSelected: (v) {
                if (v == 'edit') {
                  onEdit?.call();
                } else {
                  onDelete?.call();
                }
              },
            ),
        ],
      ),
    );
  }

  String _monthShort(int m) => [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];
}
