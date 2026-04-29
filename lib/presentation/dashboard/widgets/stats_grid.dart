import 'package:flutter/material.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/dashboard_stats_model.dart';
import 'package:sri_hr/presentation/dashboard/widgets/stat_card.dart';

class StatsGrid extends StatelessWidget {
  final DashboardStats? stats;
  const StatsGrid({super.key, this.stats});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    final cards = [
      StatCard(
        label: 'Total Employees',
        value: '${stats?.totalEmployees ?? 0}',
        icon: Icons.people_rounded,
        color: AppColors.primary,
        subtitle: 'Active employees',
      ),
      StatCard(
        label: 'Present Today',
        value: '${stats?.presentCount ?? 0}',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
        subtitle: 'Punched in today',
      ),
      StatCard(
        label: 'Absent Today',
        value: '${stats?.absentCount ?? 0}',
        icon: Icons.cancel_rounded,
        color: AppColors.error,
        subtitle: 'Not present today',
      ),
      StatCard(
        label: 'On Leave',
        value: '${stats?.leaveCount ?? 0}',
        icon: Icons.event_busy_rounded,
        color: AppColors.warning,
        subtitle: 'Approved leaves',
      ),
    ];

    return ResponsiveGridRow(
      children: cards
          .map(
            (c) => ResponsiveGridCol(
              xl: 3,
              lg: 3,
              md: 3,
              xs: 6,
              sm: 6,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                child: c,
              ),
            ),
          )
          .toList(),
    );
  }
}
