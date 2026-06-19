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
import 'package:sri_hr/presentation/mark_attendance/mark_attendance.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/loading_overlay.dart';

class Dashboard extends StatelessWidget {
  Dashboard({super.key});

  final controller = Get.isRegistered<DashboardController>()
      ? Get.find<DashboardController>()
      : Get.put(DashboardController());

  String _fmtDate(DateTime d) {
    const months = [
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
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return SafeArea(
      top: false,
      child:auth.isAdmin? AppShell(
        currentModule: 'dashboard',
        title: 'Dashboard',
        floatingActionButton: isWide ? SizedBox() : AttendanceFAB(),
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
                        // ── Greeting + refresh ──────────────────────────
                        Row(
                          children: [
                            Expanded(child: GreetingBar()),
                            IconButton(
                              onPressed: controller.loadStats,
                              icon: const Icon(
                                Icons.refresh,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),

                        // ── Date filter strip ───────────────────────────
                        Obx(
                          () => _DateFilterStrip(
                            date: controller.selectedDate.value,
                            isCustomDate: controller.isCustomDate.value,
                            formattedDate: _fmtDate(
                              controller.selectedDate.value,
                            ),
                            onTap: () => controller.pickDate(context),
                            onReset: controller.resetToToday,
                          ),
                        ),

                        const SizedBox(height: 16.0),
                        SubscriptionAlert(),
                         StatsGrid(stats: controller.stats.value,selectedDate: controller.selectedDate.value),
                        const SizedBox(height: 24),
                        ChartsRow(ctrl: controller),
                        const SizedBox(height: 24),
                        if (auth.canView("employee") ||
                            auth.canView("leave_request") ||
                            auth.canView("attendance_report") ||
                            auth.canView("punch_adjustment"))
                          QuickActions(),
                      ],
                    ),
                  ),
                ),
        ),
      ):MarkAttendance(),
    );
  }
}

// ─────────────────────────────────────────────────────────
// DATE FILTER STRIP
// ─────────────────────────────────────────────────────────
class _DateFilterStrip extends StatelessWidget {
  final DateTime date;
  final bool isCustomDate;
  final String formattedDate;
  final VoidCallback onTap;
  final VoidCallback onReset;

  const _DateFilterStrip({
    required this.date,
    required this.isCustomDate,
    required this.formattedDate,
    required this.onTap,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isCustomDate
            ? AppColors.primary.withOpacity(0.06)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCustomDate
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // ── Tappable date selector ──────────────────────
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCustomDate ? 'Filtered Date' : 'Today',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isCustomDate
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isCustomDate
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: isCustomDate
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Reset button (only visible when custom date selected) ──
          if (isCustomDate) ...[
            Container(
              width: 1,
              height: 36,
              color: AppColors.primary.withOpacity(0.2),
            ),
            InkWell(
              onTap: onReset,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.today_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
