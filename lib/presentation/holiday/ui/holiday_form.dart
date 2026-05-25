import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/utils/network_time.dart';
import 'package:sri_hr/presentation/holiday/controller/holiday_controller.dart';
import 'package:sri_hr/widgets/form_fields.dart';
import 'package:sri_hr/widgets/sri_button.dart';

class HolidayForm extends StatefulWidget {
  final dynamic item;
  final HolidayController controller;
  const HolidayForm({super.key, required this.controller, this.item});

  @override
  State<HolidayForm> createState() => _HolidayFormState();
}

class _HolidayFormState extends State<HolidayForm> {
  final formKey = GlobalKey<FormState>();
  final dateCtrl = TextEditingController();
  final reasonCtrl = TextEditingController();
  final daysCtrl = TextEditingController();

  // true when the picked date already has a holiday
  bool _dateTaken = false;

  bool get isEdit => widget.item != null;
  String? get _editId => isEdit ? (widget.item.id as String?) : null;

  @override
  void initState() {
    super.initState();
    NetworkTime.syncTime();
    dateCtrl.text = isEdit
        ? DateFormat('yyyy-MM-dd').format(widget.item.date as DateTime)
        : '';
    reasonCtrl.text = isEdit ? (widget.item.reason as String? ?? '') : '';
    daysCtrl.text = isEdit ? '${widget.item.days ?? 1}' : '1';
  }

  @override
  void dispose() {
    dateCtrl.dispose();
    reasonCtrl.dispose();
    daysCtrl.dispose();
    super.dispose();
  }

  // Called whenever a date is picked — checks if that date is already used
  void _checkDate(String date) {
    final taken = widget.controller.isDateTaken(date, excludeId: _editId);
    if (taken != _dateTaken) setState(() => _dateTaken = taken);
  }

  // ── Field validators ──────────────────────────────────────
  String? _validateDate(String? v) {
    if (v == null || v.trim().isEmpty) return 'Date is required';
    return null;
  }

  String? _validateReason(String? v) {
    if (v == null || v.trim().isEmpty) return 'Reason is required';
    final t = v.trim();
    if (t.length < 2) return 'Reason must be at least 2 characters';
    if (t.length > 100) return 'Reason must not exceed 100 characters';
    return null;
  }

  String? _validateDays(String? v) {
    if (v == null || v.trim().isEmpty) return 'No. of Days is required';
    final d = int.tryParse(v.trim());
    if (d == null) return 'Must be a whole number';
    if (d < 1) return 'Days must be at least 1';
    if (d > 30) return 'Days cannot exceed 30';
    return null;
  }

  // ── Submit ────────────────────────────────────────────────
  void _submit() {
    if (!formKey.currentState!.validate()) return;
    if (_dateTaken) return; // blocked by inline banner

    final data = {
      'date': dateCtrl.text.trim(),
      'reason': reasonCtrl.text.trim(),
      'days': int.tryParse(daysCtrl.text.trim()) ?? 1,
    };

    // Close dialog first, then fire controller (same pattern as all other forms)
    Get.back();

    if (isEdit) {
      widget.controller.updateHoliday(widget.item.id as String, data);
    } else {
      widget.controller.create(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'Edit Holiday Entry' : 'Add Holiday Entry',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date picker
                    FormFields(
                      label: 'Date',
                      type: 'date',
                      textEditingController: dateCtrl,
                      prefixIcon: Icons.calendar_today_outlined,
                      readOnly: true,
                      validator: (v) => _validateDate(v as String?),
                      onTapDate: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: NetworkTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          final formatted =
                              DateFormat('yyyy-MM-dd').format(picked);
                          setState(() => dateCtrl.text = formatted);
                          _checkDate(formatted);
                          // Re-validate the date field
                          formKey.currentState?.validate();
                        }
                      },
                    ),

                    // ── Inline date-taken banner ──────────────
                    if (_dateTaken) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 16, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'A holiday already exists on ${dateCtrl.text}. Please choose a different date.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Reason
                    FormFields(
                      label: 'Reason',
                      type: 'text',
                      textEditingController: reasonCtrl,
                      prefixIcon: Icons.info_outline,
                      topPadding: 16,
                      validator: (v) => _validateReason(v as String?),
                    ),

                    // No. of Days
                    FormFields(
                      label: 'No. of Days',
                      type: 'text',
                      textEditingController: daysCtrl,
                      prefixIcon: Icons.date_range_outlined,
                      keyboardType: TextInputType.number,
                      topPadding: 16,
                      validator: (v) => _validateDays(v as String?),
                    ),

                    const SizedBox(height: 20),

                    // ── Action buttons ────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: SriButton(
                            label: 'Cancel',
                            isOutlined: true,
                            onPressed: () => Get.back(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SriButton(
                            label: isEdit ? 'Update' : 'Add',
                            color: AppColors.accent,
                            onPressed: _submit,
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
}