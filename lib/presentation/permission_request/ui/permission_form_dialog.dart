import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/utils/network_time.dart';
import 'package:sri_hr/presentation/employee/controller/employee_controller.dart';
import 'package:sri_hr/presentation/permission_request/controller/permission_request_controller.dart';
import 'package:sri_hr/presentation/permission_request/widgets/form_label.dart';
import 'package:sri_hr/presentation/permission_request/widgets/picker_tile.dart';

class PermissionFormDialog extends StatefulWidget {
  final PermissionRequestController controller;
  const PermissionFormDialog({super.key, required this.controller});

  @override
  State<PermissionFormDialog> createState() => PermissionFormDialogState();
}

class PermissionFormDialogState extends State<PermissionFormDialog> {
  final formKey = GlobalKey<FormState>();
  final reasonCtrl = TextEditingController();

  String? employeeId;
  DateTime? date;
  TimeOfDay? fromTime;
  TimeOfDay? toTime;
  bool isLoading = false;

  late final EmployeeController empCtrl;

  @override
  void initState() {
    super.initState();
    NetworkTime.syncTime();
    empCtrl = Get.find<EmployeeController>();
    if (empCtrl.employees.isEmpty) empCtrl.loadEmployees();
  }

  @override
  void dispose() {
    reasonCtrl.dispose();
    super.dispose();
  }

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _displayTime(TimeOfDay? t) {
    if (t == null) return 'Select time';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String _displayDate(DateTime? d) {
    if (d == null) return 'Select date';
    return '${d.day.toString().padLeft(2, '0')} '
        '${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} '
        '${d.year}';
  }

  Future<void> _pickDate() async {
    final now = NetworkTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: date ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (d != null && mounted) setState(() => date = d);
  }

  Future<void> _pickFromTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: fromTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (t != null && mounted) {
      setState(() {
        fromTime = t;
        // Reset toTime if it's not after fromTime
        if (toTime != null) {
          final fromMins = t.hour * 60 + t.minute;
          final toMins = toTime!.hour * 60 + toTime!.minute;
          if (toMins <= fromMins) toTime = null;
        }
      });
    }
  }

  Future<void> _pickToTime() async {
    final initial =
        toTime ??
        (fromTime != null
            ? TimeOfDay(hour: fromTime!.hour + 1, minute: fromTime!.minute)
            : const TimeOfDay(hour: 10, minute: 0));
    final t = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (t != null && mounted) {
      // Validate: to > from
      if (fromTime != null) {
        final fromMins = fromTime!.hour * 60 + fromTime!.minute;
        final toMins = t.hour * 60 + t.minute;
        if (toMins <= fromMins) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('To Time must be after From Time'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }
      setState(() => toTime = t);
    }
  }

  int get durationMinutes {
    if (fromTime == null || toTime == null) return 0;
    return (toTime!.hour * 60 + toTime!.minute) -
        (fromTime!.hour * 60 + fromTime!.minute);
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      await widget.controller.create({
        'employee_id': employeeId,
        'request_date': date?.toIso8601String().substring(0, 10) ?? '',
        'from_time': _fmtTime(fromTime),
        'to_time': _fmtTime(toTime),
        'minutes': durationMinutes,
        'reason': reasonCtrl.text.trim(),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      // Error already shown by controller
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(4.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                decoration: const BoxDecoration(
                  color: AppColors.info,
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
                        Icons.timer_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Permission Request',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
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

              // ── Form ────────────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Employee
                      FormLabel('Employee *'),
                      const SizedBox(height: 6),
                      Obx(() {
                        final emps = empCtrl.employees;
                        final ids = emps.map((e) => e.id).toList();
                        final safe = ids.contains(employeeId)
                            ? employeeId
                            : null;
                        return DropdownButtonFormField<String>(
                          value: safe,
                          isExpanded: true,
                          decoration: _deco(
                            Icons.person_rounded,
                            'Select employee',
                          ),
                          dropdownColor: AppColors.surface,
                          validator: (v) =>
                              v == null ? 'Please select an employee' : null,
                          items: emps
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text(
                                    '${e.employeeCode} – ${e.fullName}',
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => employeeId = v),
                        );
                      }),
                      const SizedBox(height: 16),

                      // Date
                      FormLabel('Date *'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickDate,
                        child: PickerTile(
                          icon: Icons.calendar_today_rounded,
                          label: _displayDate(date),
                          selected: date != null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time row
                      FormLabel('Time *'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'From',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: _pickFromTime,
                                  child: PickerTile(
                                    icon: Icons.access_time_rounded,
                                    label: _displayTime(fromTime),
                                    selected: fromTime != null,
                                    color: AppColors.info,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: fromTime != null && toTime != null
                                  ? AppColors.info
                                  : AppColors.textMuted,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'To',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: _pickToTime,
                                  child: PickerTile(
                                    icon: Icons.access_time_filled_rounded,
                                    label: _displayTime(toTime),
                                    selected: toTime != null,
                                    disabled: fromTime == null,
                                    color: AppColors.info,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Duration chip
                      if (durationMinutes > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.info.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.timer_rounded,
                                size: 15,
                                color: AppColors.info,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                durationMinutes >= 60
                                    ? '${durationMinutes ~/ 60}h ${durationMinutes % 60}m permission'
                                    : '$durationMinutes minutes permission',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Reason
                      FormLabel('Reason (optional)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: reasonCtrl,
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        decoration: _deco(
                          Icons.notes_rounded,
                          'Enter reason for permission...',
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ── Footer ──────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
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
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: isWide ? 8.0 : 0.0,
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: isWide ? 8.0 : 0.0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Submit Request',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(IconData icon, String hint) => InputDecoration(
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
      borderSide: const BorderSide(color: AppColors.info, width: 2),
    ),
  );
}
