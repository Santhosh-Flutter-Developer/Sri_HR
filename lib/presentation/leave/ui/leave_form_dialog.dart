import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/utils/network_time.dart';
import 'package:sri_hr/presentation/employee/controller/employee_controller.dart';
import 'package:sri_hr/presentation/helper/helper.dart';
import 'package:sri_hr/presentation/leave/controller/leave_controller.dart';
import 'package:sri_hr/presentation/leave/widgets/date_picker_tile.dart';
import 'package:sri_hr/presentation/leave/widgets/field_label.dart';

class LeaveFormDialog extends StatefulWidget {
  final LeaveController controller;
  const LeaveFormDialog({super.key, required this.controller});

  @override
  State<LeaveFormDialog> createState() => LeaveFormDialogState();
}

class LeaveFormDialogState extends State<LeaveFormDialog> {
  final formKey = GlobalKey<FormState>();
  final reasonCtrl = TextEditingController();

  String? employeeId;
  DateTime? fromDate;
  DateTime? toDate;
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

  int get days {
    if (fromDate == null || toDate == null) return 0;
    return toDate!.difference(fromDate!).inDays + 1;
  }

  String fmtDate(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String displayDate(DateTime? d) {
    if (d == null) return 'Select date';
    return '${d.day.toString().padLeft(2, '0')} '
        '${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} '
        '${d.year}';
  }

  Future<void> pickFromDate() async {
    final now = NetworkTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: fromDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (d == null || !mounted) return;
    setState(() {
      fromDate = d;
      // Reset toDate if it's before new fromDate
      if (toDate != null && toDate!.isBefore(d)) toDate = null;
    });
  }

  Future<void> pickToDate() async {
    // To Date firstDate = fromDate (or today if not set)
    final first = fromDate ?? NetworkTime.now();
    final d = await showDatePicker(
      context: context,
      // initialDate must be >= firstDate
      initialDate: (toDate != null && !toDate!.isBefore(first))
          ? toDate!
          : first,
      firstDate: first,
      lastDate: first.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (d == null || !mounted) return;
    setState(() => toDate = d);
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    if (fromDate == null) {
      showErr('Please select From Date');
      return;
    }
    if (toDate == null) {
      showErr('Please select To Date');
      return;
    }
    if (days <= 0) {
      showErr('To Date must be on or after From Date');
      return;
    }

    setState(() => isLoading = true);
    try {
      await widget.controller.create({
        'employee_id': employeeId,
        'from_date': fmtDate(fromDate),
        'to_date': fmtDate(toDate),
        'days': days,
        'reason': reasonCtrl.text.trim(),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showErr('Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showErr(String msg) {
    showError(msg);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return SafeArea(
      top: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.all(4.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
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
                          Icons.event_busy_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'New Leave Request',
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

                // ── Form body ────────────────────────────
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Employee dropdown
                        const FieldLabel('Employee *'),
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
                            decoration: inputDeco(
                              Icons.person_rounded,
                              'Select employee',
                            ),
                            validator: (v) =>
                                v == null ? 'Please select an employee' : null,
                            dropdownColor: AppColors.surface,
                            items: emps
                                .map(
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
                                )
                                .toList(),
                            onChanged: (v) => setState(() => employeeId = v),
                          );
                        }),
                        const SizedBox(height: 16),

                        // Date row
                        const FieldLabel('Leave Duration *'),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // From Date
                            Expanded(
                              child: DatePickerTile(
                                label: 'From Date',
                                date: fromDate,
                                displayDate: displayDate(fromDate),
                                onTap: pickFromDate,
                                isSelected: fromDate != null,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: fromDate != null && toDate != null
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                              ),
                            ),
                            // To Date
                            Expanded(
                              child: DatePickerTile(
                                label: 'To Date',
                                date: toDate,
                                displayDate: displayDate(toDate),
                                onTap: pickToDate,
                                isSelected: toDate != null,
                                // Visually hint it's disabled if From not picked
                                disabled: fromDate == null,
                              ),
                            ),
                          ],
                        ),

                        // Days summary
                        if (days > 0) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$days day${days != 1 ? 's' : ''} of leave',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Reason
                        const FieldLabel('Reason (optional)'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: reasonCtrl,
                          maxLines: 3,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          decoration: inputDeco(
                            Icons.notes_rounded,
                            'Enter reason for leave...',
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // ── Footer buttons ───────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                          onPressed: isLoading ? null : submit,
                          style: ElevatedButton.styleFrom(
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
      ),
    );
  }

  InputDecoration inputDeco(IconData icon, String hint) => InputDecoration(
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
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
  );
}
