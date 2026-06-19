// lib/presentation/employee/widgets/company_shift_display.dart
import 'package:flutter/material.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/work_shift_model.dart';
import 'package:sri_hr/presentation/company/repository/work_shift_repository.dart';

class CompanyShiftDisplay extends StatefulWidget {
  final String? companyId;
  final String? initialWorkStart;
  final String? initialWorkEnd;
  final String? initialLunchStart;
  final String? initialLunchEnd;
  final void Function({
    required String? workStart,
    required String? workEnd,
    required String? lunchStart,
    required String? lunchEnd,
  })? onChanged;

  const CompanyShiftDisplay({
    super.key,
    required this.companyId,
    this.initialWorkStart,
    this.initialWorkEnd,
    this.initialLunchStart,
    this.initialLunchEnd,
    this.onChanged,
  });

  @override
  State<CompanyShiftDisplay> createState() => CompanyShiftDisplayState();
}

class CompanyShiftDisplayState extends State<CompanyShiftDisplay> {
  final _repo = WorkShiftRepository();
  WorkShiftModel? _shift;
  bool _loading = false;
  bool _lunchEnabled = false;

  // True once the user has manually picked any time field.
  // When true, a company change will NOT overwrite the user's entries.
  bool _userEdited = false;

  // Editable overrides — empty by default, filled from company shift
  final workStart  = TextEditingController();
  final workEnd    = TextEditingController();
  final lunchStart = TextEditingController();
  final lunchEnd   = TextEditingController();

  // Strips seconds from DB time strings: "09:15:00" → "09:15"
  static String _trimSeconds(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return t;
    return '${parts[0]}:${parts[1]}';
  }

  static String _trimSecondsNullable(String? t) =>
      t != null && t.isNotEmpty ? _trimSeconds(t) : '';

  @override
  void initState() {
    super.initState();
    _fetch(widget.companyId);
  }

  @override
  void didUpdateWidget(CompanyShiftDisplay old) {
    super.didUpdateWidget(old);
    if (old.companyId != widget.companyId) {
      // Company changed — reset user-edit flag so new company defaults load
      _userEdited = false;
      _fetch(widget.companyId);
    }
  }

  void _notify({bool fromUser = false}) {
    if (fromUser) _userEdited = true;
    widget.onChanged?.call(
      workStart: workStart.text.isNotEmpty ? workStart.text : null,
      workEnd: workEnd.text.isNotEmpty ? workEnd.text : null,
      lunchStart: lunchStart.text.isNotEmpty ? lunchStart.text : null,
      lunchEnd: lunchEnd.text.isNotEmpty ? lunchEnd.text : null,
    );
  }

  Future<void> _fetch(String? id) async {
    if (id == null || id.isEmpty) { _clear(); return; }
    setState(() => _loading = true);
    try {
      final s = await _repo.getShift(id);
      if (!mounted) return;

      // Priority order for field values:
      //   1. Employee-level saved overrides (edit mode, first load only)
      //   2. Company shift defaults (new employee OR company changed)
      // If the user has already edited the fields (_userEdited), keep their values.
      final hasEmployeeOverride = widget.initialWorkStart != null ||
          widget.initialWorkEnd != null;

      setState(() {
        _shift = s;
        if (!_userEdited) {
          workStart.text  = _trimSecondsNullable(hasEmployeeOverride ? widget.initialWorkStart  : s?.workStartTime);
          workEnd.text    = _trimSecondsNullable(hasEmployeeOverride ? widget.initialWorkEnd    : s?.workEndTime);
          lunchStart.text = _trimSecondsNullable(hasEmployeeOverride ? widget.initialLunchStart : s?.lunchStartTime);
          lunchEnd.text   = _trimSecondsNullable(hasEmployeeOverride ? widget.initialLunchEnd   : s?.lunchEndTime);
          _lunchEnabled   = lunchStart.text.isNotEmpty && lunchEnd.text.isNotEmpty;
          // If we loaded employee-level overrides, treat it as "edited" so the
          // employee override line shows in the banner immediately.
          if (hasEmployeeOverride) _userEdited = true;
        }
        _loading = false;
      });
      _notify();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _clear() {
    setState(() {
      _shift = null;
      workStart.clear(); workEnd.clear();
      lunchStart.clear(); lunchEnd.clear();
      _lunchEnabled = false;
    });
  }

  @override
  void dispose() {
    workStart.dispose(); workEnd.dispose();
    lunchStart.dispose(); lunchEnd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.companyId == null || widget.companyId!.isEmpty) return const SizedBox.shrink();

    final isWide = MediaQuery.of(context).size.width >= 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ─────────────────────────────────────────────────
        Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(7)),
              child: const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 15),
            ),
            const SizedBox(width: 8),
            const Text('Work Shift',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(width: 8),
            if (_loading) const SizedBox(
                width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        const SizedBox(height: 10),

        if (!_loading) ...[
          // No shift configured warning
          if (_shift == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accentOrange.withOpacity(0.25)),
              ),
              child: const Row(children: [
                Icon(Icons.warning_amber_rounded, size: 15, color: AppColors.accentOrange),
                SizedBox(width: 6),
                Text('No work shift configured for this company.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            )
          else
            // Company shift info banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Always show company default
                      Text(
                        'Company: ${_fmt12h(_shift!.workStartTime)} – ${_fmt12h(_shift!.workEndTime)}'
                        '${_shift!.lunchStartTime != null ? '  •  Lunch: ${_fmt12h(_shift!.lunchStartTime!)}–${_fmt12h(_shift!.lunchEndTime!)}' : ''}'
                        '  •  ${_fmtMins(_shift!.expectedWorkMinutes)}/day',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      // Show employee override line only when it differs from company
                      if (_userEdited && workStart.text.isNotEmpty && workEnd.text.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Employee: ${_fmt12h(workStart.text)} – ${_fmt12h(workEnd.text)}'
                          '${lunchStart.text.isNotEmpty && lunchEnd.text.isNotEmpty ? '  •  Lunch: ${_fmt12h(lunchStart.text)}–${_fmt12h(lunchEnd.text)}' : ''}'
                          '  •  ${_calcWorkMins()}/day',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ]),
            ),

          // Work time fields
          ResponsiveGridRow(children: [
            ResponsiveGridCol(
              xl: 6, lg: 6, md: 6, sm: 12, xs: 12,
              child: Padding(
                padding: EdgeInsets.only(top: 8, right: isWide ? 8 : 0),
                child: _ShiftTimeField(
                  controller: workStart, label: 'Work Start Time',
                  placeholder: 'e.g. 09:00 AM', icon: Icons.login_rounded,
                  onSelected: (t) { setState(() => workStart.text = t); _notify(fromUser: true); },
                ),
              ),
            ),
            ResponsiveGridCol(
              xl: 6, lg: 6, md: 6, sm: 12, xs: 12,
              child: Padding(
                padding: EdgeInsets.only(top: 8, left: isWide ? 8 : 0),
                child: _ShiftTimeField(
                  controller: workEnd, label: 'Work End Time',
                  placeholder: 'e.g. 06:00 PM', icon: Icons.logout_rounded,
                  onSelected: (t) { setState(() => workEnd.text = t); _notify(fromUser: true); },
                ),
              ),
            ),
          ]),

          const SizedBox(height: 14),

          // ── Lunch toggle ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _lunchEnabled
                  ? AppColors.primary.withOpacity(0.05)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _lunchEnabled
                      ? AppColors.primary.withOpacity(0.2)
                      : AppColors.border),
            ),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: (_lunchEnabled ? AppColors.primary : AppColors.textMuted).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(Icons.restaurant_rounded, size: 15,
                    color: _lunchEnabled ? AppColors.primary : AppColors.textMuted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _lunchEnabled ? 'Lunch break enabled' : 'Enable lunch break',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ),
              Switch.adaptive(
                value: _lunchEnabled,
                activeColor: AppColors.primary,
                onChanged: (v) {
                  setState(() {
                    _lunchEnabled = v;
                    if (!v) { lunchStart.clear(); lunchEnd.clear(); }
                  });
                  _notify(fromUser: true);
                },
              ),
            ]),
          ),

          // ── Lunch fields (conditional) ──────────────────────────────────
          if (_lunchEnabled) ...[
            const SizedBox(height: 4),
            ResponsiveGridRow(children: [
              ResponsiveGridCol(
                xl: 6, lg: 6, md: 6, sm: 12, xs: 12,
                child: Padding(
                  padding: EdgeInsets.only(top: 10, right: isWide ? 8 : 0),
                  child: _ShiftTimeField(
                    controller: lunchStart, label: 'Lunch Start Time',
                    placeholder: 'e.g. 01:00 PM', icon: Icons.restaurant_rounded,
                    onSelected: (t) { setState(() => lunchStart.text = t); _notify(fromUser: true); },
                  ),
                ),
              ),
              ResponsiveGridCol(
                xl: 6, lg: 6, md: 6, sm: 12, xs: 12,
                child: Padding(
                  padding: EdgeInsets.only(top: 10, left: isWide ? 8 : 0),
                  child: _ShiftTimeField(
                    controller: lunchEnd, label: 'Lunch End Time',
                    placeholder: 'e.g. 02:00 PM', icon: Icons.restaurant_menu_rounded,
                    onSelected: (t) { setState(() => lunchEnd.text = t); _notify(fromUser: true); },
                  ),
                ),
              ),
            ]),
          ],
        ],
      ],
    );
  }

  // Calculates net work minutes from current field values (work duration minus lunch)
  String _calcWorkMins() {
    int _toMins(String t) {
      final p = t.split(':');
      if (p.length < 2) return 0;
      return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
    }
    final start = _toMins(workStart.text);
    final end   = _toMins(workEnd.text);
    int total = end - start;
    if (total < 0) total += 24 * 60; // overnight shift
    if (lunchStart.text.isNotEmpty && lunchEnd.text.isNotEmpty) {
      final ls = _toMins(lunchStart.text);
      final le = _toMins(lunchEnd.text);
      total -= (le - ls).clamp(0, total);
    }
    return _fmtMins(total);
  }

  String _fmt12h(String t) {
    final p = _trimSeconds(t).split(':');
    if (p.length < 2) return t;
    int h = int.tryParse(p[0]) ?? 0; final m = p[1];
    final ampm = h < 12 ? 'AM' : 'PM';
    if (h == 0) h = 12; else if (h > 12) h -= 12;
    return '${h.toString().padLeft(2,'0')}:$m $ampm';
  }

  String _fmtMins(int mins) {
    return '${mins ~/ 60}h ${(mins % 60).toString().padLeft(2,'0')}m';
  }
}

class _ShiftTimeField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final IconData icon;
  final ValueChanged<String> onSelected;

  const _ShiftTimeField({
    required this.controller, required this.label, required this.placeholder,
    required this.icon, required this.onSelected,
  });

  Future<void> _pick(BuildContext context) async {
    final parts = controller.text.split(':');
    final init = TimeOfDay(
      hour:   int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '00') ?? 0,
    );
    final picked = await showTimePicker(
      context: context, initialTime: init,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) {
      onSelected('${picked.hour.toString().padLeft(2,'0')}:${picked.minute.toString().padLeft(2,'0')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller, readOnly: true,
          decoration: InputDecoration(
            labelText: label, hintText: placeholder,
            prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
            suffixIcon: const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
            filled: true, fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
      ),
    );
  }
}