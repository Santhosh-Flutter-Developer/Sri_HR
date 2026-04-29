import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/dashboard/widgets/quick_btn.dart';
import 'package:sri_hr/presentation/dashboard/widgets/section_header.dart';
import 'package:sri_hr/routes/app_routes.dart';
import 'package:sri_hr/widgets/sri_card.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return SriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Quick Actions'),
          const SizedBox(height: 16),
          ResponsiveGridRow(
            children: [
              ResponsiveGridCol(
                xl: 2,
                lg: 2,
                md: 3,
                xs: 6,
                sm: 6,
                child: QuickBtn(
                  icon: Icons.people_rounded,
                  label: 'Employees',
                  color: AppColors.primary,
                  onTap: () => Get.toNamed(AppRoutes.routeEmployee),
                ),
              ),
              ResponsiveGridCol(
                xl: 2,
                lg: 2,
                md: 3,
                xs: 6,
                sm: 6,
                child: QuickBtn(
                  icon: Icons.event_busy_rounded,
                  label: 'Leave Requests',
                  color: AppColors.warning,
                  onTap: () => Get.toNamed(AppRoutes.routeLeave),
                ),
              ),
              ResponsiveGridCol(
                xl: 2,
                lg: 2,
                md: 3,
                xs: 6,
                sm: 6,
                child: QuickBtn(
                  icon: Icons.assessment_rounded,
                  label: 'Attendance',
                  color: AppColors.info,
                  onTap: () => Get.toNamed(AppRoutes.routeAttendance),
                ),
              ),
              ResponsiveGridCol(
                xl: 2,
                lg: 2,
                md: 3,
                xs: 6,
                sm: 6,
                child: QuickBtn(
                  icon: Icons.tune_rounded,
                  label: 'Punch Adjust',
                  color: AppColors.accentGreen,
                  onTap: () => Get.toNamed(AppRoutes.routePunchAdjustment),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
