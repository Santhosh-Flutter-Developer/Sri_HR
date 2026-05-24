import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/leave_request_model.dart';
import 'package:sri_hr/data/utils/network_time.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
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

  final auth = Get.find<AuthController>();

  late final EmployeeController empCtrl;

  @override
  void initState() {
    super.initState();
    NetworkTime.syncTime();
    empCtrl = Get.find<EmployeeController>();
    if (empCtrl.employees.isEmpty) empCtrl.loadEmployees();
    if (!auth.isAdmin) {
      employeeId =
          auth.employeeId; // or auth.employeeId depending on your auth model
    }
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

  Widget _leaveStat({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 60,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
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

  // Add this getter in LeaveFormDialogState
  int get casualLeaveTotal {
    if (auth.isAdmin) {
      // For admin, show selected employee's casual leave
      final emp = empCtrl.employees.firstWhereOrNull((e) => e.id == employeeId);
      return emp?.casualLeave ?? 0;
    }
    // For employee, show their own
    final emp = empCtrl.employees.firstWhereOrNull(
      (e) => e.id == auth.employeeId,
    );
    return emp?.casualLeave ?? 0;
  }

  int get casualLeaveTaken {
    // Count approved leaves for selected employee from controller
    final empId = employeeId ?? auth.employeeId;
    return widget.controller.leaves
        .where((l) => l.employeeId == empId && l.status == LeaveStatus.approved)
        .fold(0, (sum, l) => sum + l.days);
  }

  int get casualLeaveRemaining =>
      (casualLeaveTotal - casualLeaveTaken).clamp(0, casualLeaveTotal);

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
                          final allEmps = empCtrl.employees;
                          // ✅ Non-admin sees only themselves
                          final emps = auth.isAdmin
                              ? allEmps
                              : allEmps.where((e) {
                                  return e.id == auth.employeeId;
                                }).toList();

                          final ids = emps.map((e) => e.id).toList();
                          final safe = ids.contains(employeeId)
                              ? employeeId
                              : null;
                          return DropdownButtonFormField<String>(
                            value: safe,
                            initialValue: safe,
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
                            onChanged: auth.isAdmin
                                ? (v) => setState(() => employeeId = v)
                                : null, // ✅ Lock dropdown for non-admin
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
                        // After the days summary Container
                        const SizedBox(height: 16),

                        // ✅ Casual Leave Summary Card
                        // Wrapped in Obx so it reacts when empCtrl.employees
                        // finishes loading (fixes zero values on first open)
                        Obx(() {
                          // Always read the observable list first so GetX
                          // can track it — even if we return early below.
                          final employees = empCtrl.employees.toList();
                          if (employeeId == null) return const SizedBox.shrink();
                          final empId = employeeId!;
                          final emp = employees.firstWhereOrNull((e) => e.id == empId);
                          final total = emp?.casualLeave ?? 0;
                          final taken = widget.controller.leaves
                              .where((l) =>
                                  l.employeeId == empId &&
                                  l.status == LeaveStatus.approved)
                              .fold(0, (sum, l) => sum + l.days);
                          final remaining = (total - taken).clamp(0, total);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FieldLabel('Casual Leave Summary'),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    // Total
                                    Expanded(
                                      child: _leaveStat(
                                        label: 'Total',
                                        value: total,
                                        color: AppColors.primary,
                                        icon: Icons.event_note_rounded,
                                      ),
                                    ),
                                    _verticalDivider(),
                                    // Taken
                                    Expanded(
                                      child: _leaveStat(
                                        label: 'Taken',
                                        value: taken,
                                        color: AppColors.warning,
                                        icon: Icons.event_busy_rounded,
                                      ),
                                    ),
                                    _verticalDivider(),
                                    // Remaining
                                    Expanded(
                                      child: _leaveStat(
                                        label: 'Remaining',
                                        value: remaining,
                                        color: remaining == 0
                                            ? AppColors.error
                                            : AppColors.success,
                                        icon: Icons.event_available_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),

                              // ✅ Warning if no leaves remaining
                              if (remaining == 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        size: 14,
                                        color: AppColors.error,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'No casual leaves remaining!',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // ✅ Warning if applying more days than remaining
                              if (days > 0 && days > remaining && remaining > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        size: 14,
                                        color: AppColors.warning,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Applying $days days but only $remaining remaining.',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.warning,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 12),
                            ],
                          );
                        }),

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