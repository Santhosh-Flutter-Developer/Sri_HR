import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/dashboard/controller/dashboard_controller.dart';
import 'package:sri_hr/presentation/dashboard/widgets/attendance_fab.dart';
import 'package:sri_hr/presentation/dashboard/widgets/chart_row.dart';
import 'package:sri_hr/presentation/dashboard/widgets/greeting_bar.dart';
import 'package:sri_hr/presentation/dashboard/widgets/quick_actions.dart';
import 'package:sri_hr/presentation/dashboard/widgets/stats_grid.dart';
import 'package:sri_hr/presentation/dashboard/widgets/subscription_alert.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/loading_overlay.dart';

class Dashboard extends StatelessWidget {
  Dashboard({super.key});

  final controller = Get.isRegistered<DashboardController>()
      ? Get.find<DashboardController>()
      : Get.put(DashboardController());

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return SafeArea(
      top: false,
      child: AppShell(
        currentModule: 'dashboard',
        title: 'Dashboard',
        floatingActionButton:isWide?SizedBox(): AttendanceFAB(),
        child: Obx(
          () => controller.isLoading.value
              ? const LoadingOverlay()
              : RefreshIndicator(
                  onRefresh: controller.loadStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      top: isWide ? 24.0 : 12.0,
                      left: isWide ? 24.0 : 12.0,
                      right: isWide ? 24.0 : 12.0,
                      bottom: 100.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: GreetingBar()),
                            IconButton(
                              onPressed: controller.loadStats,
                              icon: Icon(Icons.refresh, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20.0),
                        SubscriptionAlert(),
                        StatsGrid(stats: controller.stats.value),
                        const SizedBox(height: 24),
                        ChartsRow(ctrl: controller),
                        const SizedBox(height: 24),
                        QuickActions(),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
