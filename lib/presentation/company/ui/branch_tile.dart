import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/company_model.dart';
import 'package:sri_hr/presentation/company/controller/company_controller.dart';

class BranchTile extends StatelessWidget {
  final CompanyModel company;
  final CompanyController controller;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  const BranchTile({
    super.key,
    required this.company,
    required this.isActive,
    required this.onTap,
    required this.controller,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isActive
            ? AppColors.primary.withOpacity(0.06)
            : Colors.transparent,
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12.0),
                border: isActive
                    ? Border.all(
                        color: AppColors.primary.withOpacity(0.4),
                        width: 2.0,
                      )
                    : null,
              ),
              child: company.logoUrl != null && company.logoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.network(
                        company.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => controller.initials(company),
                      ),
                    )
                  : controller.initials(company),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          company.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.0,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isActive)
                        Container(
                          width: 8.0,
                          height: 8.0,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    [
                      if (company.city?.isNotEmpty == true) company.city!,
                      if (company.state?.isNotEmpty == true) company.state!,
                    ].join(', '),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 16.0,
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
