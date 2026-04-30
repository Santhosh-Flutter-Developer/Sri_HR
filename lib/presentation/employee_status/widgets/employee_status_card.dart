import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/employee_status_model.dart';

class EmployeeStatusCard extends StatelessWidget {
  final EmployeeStatusModel item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const EmployeeStatusCard({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.toggle_on_rounded,
              color: AppColors.accentGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Row(
            children: [
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: AppColors.accentGreen,
                  ),
                ),
              if (onEdit != null && onDelete != null) const SizedBox(width: 8),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.delete_rounded,
                    size: 16,
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
