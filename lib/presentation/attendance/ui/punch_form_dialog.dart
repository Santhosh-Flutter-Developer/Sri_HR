import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/attendance/widgets/punch_type_btn.dart';
import 'package:sri_hr/presentation/employee/controller/employee_controller.dart';

class PunchFormDialog extends StatefulWidget {
  final AttendanceController controller;
  final Map<String, dynamic>? prefillRow;
  const PunchFormDialog({super.key, required this.controller, this.prefillRow});
  @override
  State<PunchFormDialog> createState() => PunchFormDialogState();
}

class PunchFormDialogState extends State<PunchFormDialog> {
  final formKey = GlobalKey<FormState>();
  String? employeeId;
  DateTime? date;
  TimeOfDay? time;
  String punchType = 'in';
  bool loading = false;

  late final EmployeeController empCtrl;

  @override
  void initState() {
    super.initState();
    empCtrl = Get.find<EmployeeController>();
    if (empCtrl.employees.isEmpty) empCtrl.loadEmployees();
    // Pre-fill from existing row
    final row = widget.prefillRow;
    if (row != null) {
      employeeId = row['employeeId'] as String?;
      date = row['date'] as DateTime?;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  String displayTime(TimeOfDay? t) {
    if (t == null) return 'Select time';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  String fmt24(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String displayDate(DateTime? d) {
    if (d == null) return 'Select date';
    return '${d.day.toString().padLeft(2, '0')} '
        '${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} '
        '${d.year}';
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: date ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.warning),
        ),
        child: child!,
      ),
    );
    if (d != null && mounted) setState(() => date = d);
  }

  Future<void> pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: time ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.warning),
        ),
        child: child!,
      ),
    );
    if (t != null && mounted) setState(() => time = t);
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    if (date == null) {
      snack('Please select a date');
      return;
    }
    if (time == null) {
      snack('Please select a time');
      return;
    }
    setState(() => loading = true);
    try {
      final dt = DateTime(
        date!.year,
        date!.month,
        date!.day,
        time!.hour,
        time!.minute,
      );
      await widget.controller.adjustPunch({
        'employee_id': employeeId,
        'date': date!.toIso8601String().substring(0, 10),
        'punch_time': dt.toIso8601String(),
        'punch_type': punchType,
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      snack('Error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
              decoration: const BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Manual Punch Adjustment',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    // Employee
                    Obx(() {
                      final emps = empCtrl.employees;
                      final ids = emps.map((e) => e.id).toList();
                      final safe = ids.contains(employeeId) ? employeeId : null;
                      return DropdownButtonFormField<String>(
                        value: safe,
                        isExpanded: true,
                        decoration: deco(
                          Icons.person_rounded,
                          'Select employee',
                        ),
                        dropdownColor: AppColors.surface,
                        validator: (v) =>
                            v == null ? 'Select an employee' : null,
                        items: emps
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.id,
                                child: Text(
                                  '${e.employeeCode} – ${e.fullName}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => employeeId = v),
                      );
                    }),
                    const SizedBox(height: 14),

                    // Date
                    GestureDetector(
                      onTap: pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: date != null
                                ? AppColors.warning.withOpacity(0.5)
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: date != null
                                  ? AppColors.warning
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                displayDate(date),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: date != null
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                  fontWeight: date != null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            const Text(
                              'Date *',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Time (picker)
                    GestureDetector(
                      onTap: pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: time != null
                                ? AppColors.warning.withOpacity(0.5)
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 18,
                              color: time != null
                                  ? AppColors.warning
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                time != null
                                    ? displayTime(time)
                                    : 'Select Time',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: time != null
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                  fontWeight: time != null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (time != null)
                              Text(
                                fmt24(time!),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            const SizedBox(width: 6),
                            const Text(
                              'Time *',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Punch type
                    Row(
                      children: [
                        const Text(
                          'Punch Type:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        PunchTypeBtn(
                          label: 'IN',
                          selected: punchType == 'in',
                          color: AppColors.success,
                          onTap: () => setState(() => punchType = 'in'),
                        ),
                        const SizedBox(width: 10),
                        PunchTypeBtn(
                          label: 'OUT',
                          selected: punchType == 'out',
                          color: AppColors.error,
                          onTap: () => setState(() => punchType = 'out'),
                        ),
                        if (date != null && time != null) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${date!.day.toString().padLeft(2, '0')}/'
                              '${date!.month.toString().padLeft(2, '0')} '
                              '${fmt24(time!)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: loading ? null : submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Save Adjustment',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
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

  InputDecoration deco(IconData icon, String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
    prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
    filled: true,
    fillColor: AppColors.surfaceVariant,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.warning, width: 2),
    ),
  );
}
