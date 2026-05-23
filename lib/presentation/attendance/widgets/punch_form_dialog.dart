import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/utils/network_time.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/attendance/widgets/picker_box.dart';
import 'package:sri_hr/presentation/attendance/widgets/punch_type_btn.dart';
import 'package:sri_hr/presentation/employee/controller/employee_controller.dart';
import 'package:sri_hr/presentation/helper/helper.dart';

class PunchFormDialog extends StatefulWidget {
  final AttendanceController controller;
  final Map<String, dynamic>? prefillRow;
  const PunchFormDialog({super.key, required this.controller, this.prefillRow});

  @override
  State<PunchFormDialog> createState() => _PunchFormDialogState();
}

class _PunchFormDialogState extends State<PunchFormDialog> {
  final formKey = GlobalKey<FormState>();
  String? empId;
  DateTime? date;
  TimeOfDay? time;
  String punchType = 'in';
  bool loading = false;

  late final EmployeeController empCtrl;

  @override
  void initState() {
    super.initState();
    NetworkTime.syncTime();
    empCtrl = Get.find<EmployeeController>();
    final row = widget.prefillRow;
    if (row != null) {
      empId = row['employeeId'] as String?;
      date = row['date'] as DateTime?;
    }
  }

  String displayTime(TimeOfDay? t) {
    if (t == null) return 'Select time';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    return '$h:${t.minute.toString().padLeft(2, '0')} ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  String fmt24(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String displayDate(DateTime? d) {
    if (d == null) return 'Select date';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: date ?? NetworkTime.now(),
      firstDate: DateTime(2020),
      lastDate: NetworkTime.now(),
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
      snack('Select a date');
      return;
    }
    if (time == null) {
      snack('Select a time');
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
        'employee_id': empId,
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

  void snack(String msg) {
    showError(msg);
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(msg),
    //     backgroundColor: AppColors.error,
    //     behavior: SnackBarBehavior.floating,
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(20.0),
      ),
      insetPadding: const EdgeInsets.all(4.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
              decoration: const BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: Colors.white),
                  const SizedBox(width: 10),
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    Obx(() {
                      final ids = empCtrl.employees.map((e) => e.id).toList();
                      return DropdownButtonFormField<String>(
                        value: ids.contains(empId) ? empId : null,
                        isExpanded: true,
                        decoration: deco(
                          Icons.person_rounded,
                          'Select employee',
                        ),
                        validator: (v) => v == null ? 'Required' : null,
                        items: empCtrl.employees
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
                        onChanged: (v) => setState(() => empId = v),
                      );
                    }),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: pickDate,
                      child: PickerBox(
                        icon: Icons.calendar_today_rounded,
                        label: displayDate(date),
                        trailingLabel: 'Date *',
                        selected: date != null,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: pickTime,
                      child: PickerBox(
                        icon: Icons.access_time_rounded,
                        label: time != null
                            ? '${displayTime(time!)}  (${fmt24(time!)})'
                            : 'Select Time',
                        trailingLabel: 'Time *',
                        selected: time != null,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      ],
                    ),
                    const SizedBox(height: 20),
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
    hintStyle: const TextStyle(color: AppColors.textMuted),
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
