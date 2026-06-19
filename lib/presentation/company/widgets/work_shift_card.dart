// lib/presentation/company/widgets/work_shift_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/work_shift_model.dart';
import 'package:sri_hr/presentation/company/repository/work_shift_repository.dart';
import 'package:sri_hr/presentation/company/widgets/sri_detail_card.dart';

class WorkShiftCard extends StatefulWidget {
  final String companyId;
  final bool parentEditing;
  const WorkShiftCard({super.key, required this.companyId, required this.parentEditing});

  @override
  State<WorkShiftCard> createState() => WorkShiftCardState();

  /// Call this from a parent [GlobalKey<_WorkShiftCardState>] to save the
  /// shift as part of the parent's Save Changes flow.
  /// Returns true on success, false on validation failure or error.
  static Future<bool> saveViaKey(GlobalKey<WorkShiftCardState> key) {
    return key.currentState?._save() ?? Future.value(true);
  }
}

class WorkShiftCardState extends State<WorkShiftCard> {
  final _repo = WorkShiftRepository();
  WorkShiftModel? _shift;
  bool _loading = true;
  bool _saving = false;

  // lunch enabled toggle
  bool _lunchEnabled = false;

  // controllers — start empty (no default values)
  final _workStart  = TextEditingController();
  final _workEnd    = TextEditingController();
  final _lunchStart = TextEditingController();
  final _lunchEnd   = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(WorkShiftCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Parent cancelled editing — restore controllers to last saved values
    if (oldWidget.parentEditing && !widget.parentEditing) {
      _resetToSaved();
    }
  }

  /// Restore all controllers to the last successfully saved shift data.
  void _resetToSaved() {
    setState(() {
      _workStart.text  = _shift?.workStartTime  ?? '';
      _workEnd.text    = _shift?.workEndTime    ?? '';
      _lunchStart.text = _shift?.lunchStartTime ?? '';
      _lunchEnd.text   = _shift?.lunchEndTime   ?? '';
      _lunchEnabled    = (_shift?.lunchStartTime?.isNotEmpty ?? false) &&
                         (_shift?.lunchEndTime?.isNotEmpty   ?? false);
    });
  }

  Future<void> _load() async {
    try {
      final s = await _repo.getShift(widget.companyId);
      if (!mounted) return;
      setState(() {
        _shift = s;
        // Only populate if previously saved — never show defaults
        _workStart.text  = s?.workStartTime  ?? '';
        _workEnd.text    = s?.workEndTime    ?? '';
        _lunchStart.text = s?.lunchStartTime ?? '';
        _lunchEnd.text   = s?.lunchEndTime   ?? '';
        // Enable lunch only if both times were previously saved
        _lunchEnabled = (s?.lunchStartTime?.isNotEmpty ?? false) &&
                        (s?.lunchEndTime?.isNotEmpty   ?? false);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ── Validation ─────────────────────────────────────────────────────────────
  String? _validateTime(String val, String fieldName) {
    if (val.trim().isEmpty) return '$fieldName is required';
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(val.trim())) return 'Invalid format';
    final parts = val.split(':');
    final h = int.tryParse(parts[0]) ?? -1;
    final m = int.tryParse(parts[1]) ?? -1;
    if (h < 0 || h > 23) return 'Hour must be 00-23';
    if (m < 0 || m > 59) return 'Minute must be 00-59';
    return null;
  }

  bool _validate() {
    // Work start / end required
    final wsErr = _validateTime(_workStart.text, 'Work Start Time');
    if (wsErr != null) { _snack('Validation', wsErr); return false; }
    final weErr = _validateTime(_workEnd.text, 'Work End Time');
    if (weErr != null) { _snack('Validation', weErr); return false; }

    // Work end must be after start
    final startMins = _timeToMins(_workStart.text);
    final endMins   = _timeToMins(_workEnd.text);
    if (endMins <= startMins) {
      _snack('Validation', 'Work End Time must be after Work Start Time');
      return false;
    }

    if (_lunchEnabled) {
      final lsErr = _validateTime(_lunchStart.text, 'Lunch Start Time');
      if (lsErr != null) { _snack('Validation', lsErr); return false; }
      final leErr = _validateTime(_lunchEnd.text, 'Lunch End Time');
      if (leErr != null) { _snack('Validation', leErr); return false; }

      final lunchStartMins = _timeToMins(_lunchStart.text);
      final lunchEndMins   = _timeToMins(_lunchEnd.text);

      if (lunchEndMins <= lunchStartMins) {
        _snack('Validation', 'Lunch End Time must be after Lunch Start Time');
        return false;
      }
      if (lunchStartMins < startMins || lunchEndMins > endMins) {
        _snack('Validation', 'Lunch time must be within work hours');
        return false;
      }
    }

    return true;
  }

  int _timeToMins(String t) {
    final p = t.split(':');
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  }

  void _snack(String title, String msg) => Get.snackbar(
    title, msg,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: AppColors.accentOrange,
    colorText: Colors.white,
    duration: const Duration(seconds: 3),
  );

  Future<bool> _save() async {
    if (!_validate()) return false;
    setState(() => _saving = true);
    try {
      final updated = await _repo.upsertShift(WorkShiftModel(
        id: _shift?.id ?? '',
        companyId: widget.companyId,
        workStartTime:  _workStart.text.trim(),
        workEndTime:    _workEnd.text.trim(),
        lunchStartTime: _lunchEnabled ? _lunchStart.text.trim() : null,
        lunchEndTime:   _lunchEnabled ? _lunchEnd.text.trim()   : null,
        createdAt: _shift?.createdAt ?? DateTime.now(),
      ));
      if (!mounted) return true;
      setState(() => _shift = updated);
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to save shift: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.accentRed,
          colorText: Colors.white);
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _workStart.dispose();
    _workEnd.dispose();
    _lunchStart.dispose();
    _lunchEnd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    final editing = widget.parentEditing;

    return SriDetailCard(
      title: 'Work Shift',
      icon: Icons.schedule_rounded,
      children: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[

          // ── Saved shift summary banner ─────────────────────────────────────
          if (_shift != null && _shift!.workStartTime.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 12,
                      children: [
                        _infoChip(Icons.login_rounded, 'Start: ${_fmt12h(_shift!.workStartTime)}'),
                        _infoChip(Icons.logout_rounded, 'End: ${_fmt12h(_shift!.workEndTime)}'),
                        if (_shift!.lunchStartTime != null)
                          _infoChip(Icons.restaurant_rounded,
                              'Lunch: ${_fmt12h(_shift!.lunchStartTime!)} – ${_fmt12h(_shift!.lunchEndTime!)}'),
                        _infoChip(Icons.timer_outlined,
                            'Expected: ${_fmtMins(_shift!.expectedWorkMinutes)}/day'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ] else if (!editing) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accentOrange.withOpacity(0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 15, color: AppColors.accentOrange),
                  SizedBox(width: 8),
                  Text('No shift configured. Click Edit to set work hours.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],

          // ── Work time fields ───────────────────────────────────────────────
          ResponsiveGridRow(
            children: [
              ResponsiveGridCol(
                xl: 6, lg: 6, md: 6, sm: 12, xs: 12,
                child: Padding(
                  padding: EdgeInsets.only(top: 8, right: isWide ? 8 : 0),
                  child: _TimeField(
                    controller: _workStart,
                    label: 'Work Start Time',
                    placeholder: 'e.g. 09:00 AM',
                    icon: Icons.login_rounded,
                    readOnly: !editing,
                    onTimeSelected: (t) { if (editing) setState(() => _workStart.text = t); },
                  ),
                ),
              ),
              ResponsiveGridCol(
                xl: 6, lg: 6, md: 6, sm: 12, xs: 12,
                child: Padding(
                  padding: EdgeInsets.only(top: 8, left: isWide ? 8 : 0),
                  child: _TimeField(
                    controller: _workEnd,
                    label: 'Work End Time',
                    placeholder: 'e.g. 06:00 PM',
                    icon: Icons.logout_rounded,
                    readOnly: !editing,
                    onTimeSelected: (t) { if (editing) setState(() => _workEnd.text = t); },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Lunch toggle ───────────────────────────────────────────────────
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
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: (_lunchEnabled ? AppColors.primary : AppColors.textMuted)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.restaurant_rounded,
                      size: 16,
                      color: _lunchEnabled ? AppColors.primary : AppColors.textMuted),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Lunch Break',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      Text(
                        _lunchEnabled
                            ? 'Lunch time will be excluded from expected hours'
                            : 'Enable to configure lunch break timings',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _lunchEnabled,
                  activeColor: AppColors.primary,
                  onChanged: editing
                      ? (v) {
                          setState(() {
                            _lunchEnabled = v;
                            if (!v) {
                              _lunchStart.clear();
                              _lunchEnd.clear();
                            }
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),

          // ── Lunch fields (conditional) ─────────────────────────────────────
          if (_lunchEnabled) ...[
            const SizedBox(height: 4),
            ResponsiveGridRow(
              children: [
                ResponsiveGridCol(
                  xl: 6, lg: 6, md: 6, sm: 12, xs: 12,
                  child: Padding(
                    padding: EdgeInsets.only(top: 10, right: isWide ? 8 : 0),
                    child: _TimeField(
                      controller: _lunchStart,
                      label: 'Lunch Start Time',
                      placeholder: 'e.g. 01:00 PM',
                      icon: Icons.restaurant_rounded,
                      readOnly: !editing,
                      onTimeSelected: (t) { if (editing) setState(() => _lunchStart.text = t); },
                    ),
                  ),
                ),
                ResponsiveGridCol(
                  xl: 6, lg: 6, md: 6, sm: 12, xs: 12,
                  child: Padding(
                    padding: EdgeInsets.only(top: 10, left: isWide ? 8 : 0),
                    child: _TimeField(
                      controller: _lunchEnd,
                      label: 'Lunch End Time',
                      placeholder: 'e.g. 02:00 PM',
                      icon: Icons.restaurant_menu_rounded,
                      readOnly: !editing,
                      onTimeSelected: (t) { if (editing) setState(() => _lunchEnd.text = t); },
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: AppColors.primary),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ],
  );

  String _fmt12h(String t) {
    final p = t.split(':');
    if (p.length < 2) return t;
    int h = int.tryParse(p[0]) ?? 0;
    final m = p[1];
    final ampm = h < 12 ? 'AM' : 'PM';
    if (h == 0) h = 12; else if (h > 12) h -= 12;
    return '${h.toString().padLeft(2, '0')}:$m $ampm';
  }

  String _fmtMins(int mins) {
    final h = mins ~/ 60; final m = mins % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
}

// ─── Reusable time picker field ────────────────────────────────────────────────
class _TimeField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final IconData icon;
  final bool readOnly;
  final ValueChanged<String> onTimeSelected;

  const _TimeField({
    required this.controller,
    required this.label,
    required this.placeholder,
    required this.icon,
    required this.readOnly,
    required this.onTimeSelected,
  });

  Future<void> _pick(BuildContext context) async {
    final parts = controller.text.split(':');
    final init = TimeOfDay(
      hour:   int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '00') ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: init,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) {
      onTimeSelected(
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: readOnly ? null : () => _pick(context),
      child: AbsorbPointer(
        absorbing: true,
        child: TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            hintText: readOnly ? null : placeholder,
            prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
            suffixIcon: readOnly
                ? null
                : const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
            filled: true,
            fillColor: readOnly ? AppColors.surfaceVariant : AppColors.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}