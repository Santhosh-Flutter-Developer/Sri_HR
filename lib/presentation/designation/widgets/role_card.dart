import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class RoleCard extends StatelessWidget {
  final dynamic role;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const RoleCard({
    super.key,
    required this.role,
    required this.isSelected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          // margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  role.isAdmin
                      ? Icons.admin_panel_settings
                      : Icons.badge_rounded,
                  color: isSelected ? Colors.white : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${role.workingFrom} – ${role.workingTo}  •  ${role.casualLeave}d leave',
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? Colors.white.withOpacity(0.7)
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                iconColor: isSelected ? Colors.white : AppColors.primary,
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
        ),
      ),
    );
  }
}
