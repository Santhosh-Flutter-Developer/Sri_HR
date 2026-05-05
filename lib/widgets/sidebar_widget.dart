import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/constants/app_constants.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/company/controller/company_controller.dart';
import 'package:sri_hr/routes/app_routes.dart';
import 'package:sri_hr/widgets/nav_item.dart';

class SidebarWidget extends StatelessWidget {
  final String currentModule;
  SidebarWidget({super.key, required this.currentModule});
  final CompController = Get.isRegistered<CompanyController>()
      ? Get.find<CompanyController>()
      : Get.put(CompanyController());
  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return SafeArea(
      child: Container(
        width: 260,
        color: AppColors.sidebarBg,
        child: Column(
          children: [
            // Logo area
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.corporate_fare,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Sri HR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Nunito',
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Subscription badge
            Obx(() {
              final sub = auth.subscription.value;
              if (sub == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: sub.isActive
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sub.isActive
                        ? AppColors.primaryLight.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      sub.isActive ? Icons.verified : Icons.warning_rounded,
                      size: 14,
                      color: sub.isActive
                          ? AppColors.primaryLight
                          : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sub.isActive
                            ? '${sub.plan.name.toUpperCase()} · ${sub.daysRemaining}d left'
                            : 'Subscription Expired',
                        style: TextStyle(
                          fontSize: 11,
                          color: sub.isActive
                              ? AppColors.primaryLight
                              : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            _buildCompanySwitcher(context),
            // Menu items
            Expanded(
              child: Obx(
                () => ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  children: auth.visibleModules.map((module) {
                    final isSelected = currentModule == module;
                    final icon = iconFor(module);
                    final label = AppConstants.moduleLabels[module] ?? module;
                    return NavItem(
                      icon: icon,
                      label: label,
                      isSelected: isSelected,
                      onTap: () {
                        final route = routeFor(module);
                        if (route != null) Get.offAllNamed(route);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            // User footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Obx(
                () => Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.primaryLight,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.currentUser.value?.fullName ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            auth.isAdmin ? 'Administrator' : 'Employee',
                            style: const TextStyle(
                              color: AppColors.sidebarIcon,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => showLogoutDialog(context, auth),
                      child: const Icon(
                        Icons.logout,
                        color: AppColors.sidebarIcon,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showLogoutDialog(BuildContext context, AuthController auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              auth.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanySwitcher(BuildContext context) {
    final companyCtrl = Get.find<CompanyController>();
    return Obx(() {
      final companies = companyCtrl.companies;
      final active = companyCtrl.activeCompany.value;
      if (companies.isEmpty || active == null) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: companies.length == 1
            // ── Single company: just show name ──────────
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          active.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        active.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            // ── Multi company: show dropdown switcher ───
            : PopupMenuButton<String>(
                tooltip: 'Switch Branch',
                offset: const Offset(260, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                color: const Color(0xFF1E293B),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            active.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              active.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${companies.length} branches',
                              style: const TextStyle(
                                color: AppColors.sidebarIcon,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.unfold_more_rounded,
                        color: AppColors.sidebarIcon,
                        size: 16,
                      ),
                    ],
                  ),
                ),
                itemBuilder: (_) => [
                  // Header
                  PopupMenuItem(
                    enabled: false,
                    height: 36,
                    child: Text(
                      'Switch Branch',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  // Branch items
                  ...companies.map(
                    (c) => PopupMenuItem<String>(
                      value: c.id,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: c.id == active.id
                                    ? AppColors.primary.withOpacity(0.25)
                                    : AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  c.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: c.id == active.id
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (c.city?.isNotEmpty == true)
                                    Text(
                                      c.city!,
                                      style: const TextStyle(
                                        color: AppColors.sidebarIcon,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (c.id == active.id)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: 16,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Manage link
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: '__manage__',
                    child: Row(
                      children: const [
                        Icon(
                          Icons.settings_rounded,
                          color: AppColors.sidebarIcon,
                          size: 15,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Manage Branches',
                          style: TextStyle(
                            color: AppColors.sidebarText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == '__manage__') {
                    Get.toNamed(AppRoutes.routeCompany);
                  } else {
                    final selected = companies.firstWhere((c) => c.id == value);
                    companyCtrl.switchCompany(selected);
                  }
                },
              ),
      );
    });
  }

  IconData iconFor(String module) {
    return switch (module) {
      'dashboard' => Icons.dashboard_rounded,
      'designation' => Icons.badge_rounded,
      'company' => Icons.business_rounded,
      'department' => Icons.account_tree_rounded,
      'employee_status' => Icons.toggle_on_rounded,
      'salary_type' => Icons.payments_rounded,
      'employee' => Icons.people_rounded,
      'holiday' => Icons.celebration_rounded,
      'leave_request' => Icons.event_busy_rounded,
      'permission_request' => Icons.timer_rounded,
      'attendance_report' => Icons.assessment_rounded,
      'punch_adjustment' => Icons.tune_rounded,
      'subscription' => Icons.card_membership_rounded,
      _ => Icons.circle,
    };
  }

  String? routeFor(String module) {
    return switch (module) {
      'dashboard' => AppRoutes.routeDashboard,
      'designation' => AppRoutes.routeDesignation,
      'company' => AppRoutes.routeCompany,
      'department' => AppRoutes.routeDepartment,
      'employee_status' => AppRoutes.routeEmployeeStatus,
      'salary_type' => AppRoutes.routeSalaryType,
      'employee' => AppRoutes.routeEmployee,
      'holiday' => AppRoutes.routeHoliday,
      'leave_request' => AppRoutes.routeLeave,
      'permission_request' => AppRoutes.routePermission,
      'attendance_report' => AppRoutes.routeAttendance,
      'punch_adjustment' => AppRoutes.routePunchAdjustment,
      'subscription' => AppRoutes.routeSubscription,
      _ => null,
    };
  }
}
