import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/utils/network_time.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/attendance/widgets/date_tap_box.dart';
import 'package:sri_hr/presentation/attendance/widgets/quick_btn.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/employee/controller/employee_controller.dart';

class FilterSheet extends StatefulWidget {
  final AttendanceController controller;
  const FilterSheet({super.key, required this.controller});
  @override
  State<FilterSheet> createState() => FilterSheetState();
}

class FilterSheetState extends State<FilterSheet> {
  late DateTime? from;
  late DateTime? to;
  String? empId;
  final auth = Get.find<AuthController>();

  late final EmployeeController empCtrl;

  @override
  void initState() {
    super.initState();
    NetworkTime.syncTime();
    from = widget.controller.fromDate.value;
    to = widget.controller.toDate.value;
    empId = !auth.isAdmin
        ? auth.employeeId
        : widget.controller.filterEmployeeId.value;
    empCtrl = Get.find<EmployeeController>();
  }

  String fmtDate(DateTime? d) {
    if (d == null) return 'Select';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> pickDate(bool isFrom) async {
    final d = await showDatePicker(
      context: context,
      initialDate: (isFrom ? from : to) ?? NetworkTime.now(),
      firstDate: DateTime(2020),
      lastDate: NetworkTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (d != null && mounted) setState(() => isFrom ? from = d : to = d);
  }

  void quickSelect(String preset) {
    final now = NetworkTime.now();
    setState(() {
      switch (preset) {
        case 'today':
          from = now;
          to = now;
        case 'week':
          from = now.subtract(Duration(days: now.weekday - 1));
          to = now;
        case 'month':
          from = DateTime(now.year, now.month, 1);
          to = now;
        case 'last_month':
          from = DateTime(now.year, now.month - 1, 1);
          to = DateTime(now.year, now.month, 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Filter Attendance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick selects
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  QuickBtn('Today', () => quickSelect('today')),
                  QuickBtn('This Week', () => quickSelect('week')),
                  QuickBtn('This Month', () => quickSelect('month')),
                  QuickBtn('Last Month', () => quickSelect('last_month')),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Date range
            Row(
              children: [
                Expanded(
                  child: DateTapBox(
                    label: 'From Date',
                    value: fmtDate(from),
                    onTap: () => pickDate(true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
                Expanded(
                  child: DateTapBox(
                    label: 'To Date',
                    value: fmtDate(to),
                    onTap: () => pickDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Employee filter
            Obx(() {
              final allEmps = empCtrl.employees;
              // ✅ Non-admin sees only themselves
              final emps = auth.isAdmin
                  ? allEmps
                  : allEmps.where((e) {
                      return e.id == auth.employeeId;
                    }).toList();
              final ids = emps.map((e) => e.id).toList();
              final safe = ids.contains(empId) ? empId : null;
              return DropdownButtonFormField<String>(
                value: safe,
                initialValue: safe,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Employee (optional)',
                  prefixIcon: Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                ),
                items: [
                  if (auth.isAdmin)
                    const DropdownMenuItem(
                      value: null,
                      child: Text(
                        'All Employees',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ...emps.map(
                    (e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(
                        '${e.employeeCode} – ${e.fullName}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: auth.isAdmin
                    ? (v) => setState(() => empId = v)
                    : null,
              );
            }),
            const SizedBox(height: 20),

            // Apply / Reset
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.controller.clearFilters();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.controller.applyFilters(
                        from: from,
                        to: to,
                        employeeId: empId ?? '',
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Filter',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
