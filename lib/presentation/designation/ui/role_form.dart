import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/designation/controller/role_controller.dart';
import 'package:sri_hr/widgets/form_fields.dart';
import 'package:sri_hr/widgets/sri_button.dart';

class RoleForm extends StatefulWidget {
  final dynamic role;
  final RoleController controller;
  const RoleForm({super.key, this.role, required this.controller});

  @override
  State<RoleForm> createState() => _RoleFormState();
}

class _RoleFormState extends State<RoleForm> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController name, from, to, breakTime, permMin, leave;
  RxBool isAdmin = false.obs;
  bool get isEdit => widget.role != null;

  // ── Validators ────────────────────────────────────────────────────

  /// Role name: 2–50 chars, letters/spaces/hyphens only, no leading/trailing spaces,
  /// and must be unique within this company (case-insensitive).
  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Role Name is required';
    final trimmed = v.trim();
    if (trimmed.length < 2) return 'Role Name must be at least 2 characters';
    if (trimmed.length > 50) return 'Role Name must not exceed 50 characters';
    if (!RegExp(r"^[a-zA-Z\s\-]+$").hasMatch(trimmed)) {
      return 'Only letters, spaces, and hyphens allowed';
    }
    // ── Duplicate check (case-insensitive, company-scoped) ──
    final excludeId = isEdit ? widget.role.id as String? : null;
    if (widget.controller.isDuplicateName(trimmed, excludeId: excludeId)) {
      return '"$trimmed" already exists. Please use a unique designation name.';
    }
    return null;
  }

  /// HH:MM format guard (also used for "from" and "to").
  String? _validateTimeFormat(String? v, String fieldName) {
    if (v == null || v.trim().isEmpty) return '$fieldName is required';
    if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(v.trim())) {
      return '$fieldName must be a valid time (HH:MM)';
    }
    return null;
  }

  /// "To" must be strictly after "From".
  String? _validateToTime(String? v) {
    final formatErr = _validateTimeFormat(v, 'To Time');
    if (formatErr != null) return formatErr;

    final fromParts = from.text.split(':');
    final toParts = v!.split(':');
    final fromMinutes = int.parse(fromParts[0]) * 60 + int.parse(fromParts[1]);
    final toMinutes = int.parse(toParts[0]) * 60 + int.parse(toParts[1]);

    if (toMinutes <= fromMinutes) {
      return 'To Time must be after From Time';
    }

    // Shift must be at least 1 hour
    if (toMinutes - fromMinutes < 60) {
      return 'Shift duration must be at least 1 hour';
    }

    return null;
  }

  /// Break time: 0–120 mins, must be less than shift duration.
  String? _validateBreakTime(String? v) {
    if (v == null || v.trim().isEmpty) return 'Break Time is required';
    final mins = int.tryParse(v.trim());
    if (mins == null) return 'Break Time must be a whole number';
    if (mins < 0) return 'Break Time cannot be negative';
    if (mins > 120) return 'Break Time cannot exceed 120 minutes';

    // Ensure break doesn't eat the whole shift
    final fromParts = from.text.split(':');
    final toParts = to.text.split(':');
    if (fromParts.length == 2 && toParts.length == 2) {
      final shiftMins =
          (int.tryParse(toParts[0]) ?? 0) * 60 +
          (int.tryParse(toParts[1]) ?? 0) -
          (int.tryParse(fromParts[0]) ?? 0) * 60 -
          (int.tryParse(fromParts[1]) ?? 0);
      if (shiftMins > 0 && mins >= shiftMins) {
        return 'Break Time must be less than the total shift duration';
      }
    }
    return null;
  }

  /// Permission: 0–240 mins.
  String? _validatePermission(String? v) {
    if (v == null || v.trim().isEmpty) return 'Permission is required';
    final mins = int.tryParse(v.trim());
    if (mins == null) return 'Permission must be a whole number';
    if (mins < 0) return 'Permission cannot be negative';
    if (mins > 240) return 'Permission cannot exceed 240 minutes per month';
    return null;
  }

  /// Casual leave: 0–30 days (whole numbers only).
  String? _validateLeave(String? v) {
    if (v == null || v.trim().isEmpty) return 'Casual Leave is required';
    final days = int.tryParse(v.trim());
    if (days == null) return 'Casual Leave must be a whole number';
    if (days < 0) return 'Casual Leave cannot be negative';
    if (days > 30) return 'Casual Leave cannot exceed 30 days per year';
    return null;
  }

  // ── Field definitions ─────────────────────────────────────────────

  List<dynamic> get fields => [
    {
      "label": "Role Name",
      "controller": name,
      "type": "text",
      "keyboardType": TextInputType.text,
      "prefixIcon": Icons.badge_outlined,
      "validator": (v) => _validateName(v as String?), // ✅
      "bottomPadding": 24.0,
    },
    /*{
      "label": "From Time",
      "controller": from,
      "type": "text",
      "keyboardType": TextInputType.text,
      "readOnly": true,
      "prefixIcon": Icons.schedule,
      "onTap": () => pickTime(from),
      "validator": (v) => _validateTimeFormat(v as String?, 'From Time'), // ✅
      "xl": 12,
      "lg": 12,
      "md": 12,
      "xs": 12,
      "sm": 12,
    },
    {
      "label": "To Time",
      "controller": to,
      "type": "text",
      "keyboardType": TextInputType.text,
      "prefixIcon": Icons.schedule,
      "readOnly": true,
      "onTap": () => pickTime(to),
      "validator": (v) => _validateToTime(v as String?), // ✅
      "topPadding": 16.0,
      "xl": 12,
      "lg": 12,
      "md": 12,
      "xs": 12,
      "sm": 12,
    },
    {
      "label": "Break Time (mins)",
      "controller": breakTime,
      "type": "text",
      "prefixIcon": Icons.coffee_outlined,
      "keyboardType": TextInputType.number,
      "validator": (v) => _validateBreakTime(v as String?), // ✅
      "topPadding": 16.0,
      "xl": 12,
      "lg": 12,
      "md": 12,
      "xs": 12,
      "sm": 12,
    },*/
    {
      "label": "Permission (mins)",
      "controller": permMin,
      "type": "text",
      "keyboardType": TextInputType.number,
      "prefixIcon": Icons.timelapse_outlined,
      "validator": (v) => _validatePermission(v as String?), // ✅
      "topPadding": 16.0,
      "xl": 12,
      "lg": 12,
      "md": 12,
      "xs": 12,
      "sm": 12,
    },
    {
      "label": "Casual Leave (days)",
      "controller": leave,
      "type": "text",
      "prefixIcon": Icons.event_available_outlined,
      "keyboardType": TextInputType.number,
      "validator": (v) => _validateLeave(v as String?), // ✅
      "topPadding": 16.0,
    },
    {
      "label": "Admin Role",
      "type": "switch",
      "switchValue": isAdmin.value,
      "onSwitchChanged": (v) => isAdmin.value = v,
      "topPadding": 16.0,
    },
  ];

 @override
void initState() {
  super.initState();
  final r = widget.role;
  name = TextEditingController(text: r?.name ?? '');
  // from = TextEditingController(text: _formatTime(r?.workingFrom ?? '09:00'));
  // to = TextEditingController(text: _formatTime(r?.workingTo ?? '18:00'));
  // breakTime = TextEditingController(text: '${r?.breakMinutes ?? 30}');
  permMin = TextEditingController(text: '${r?.permissionMinutes ?? 60}');
  leave = TextEditingController(text: '${r?.casualLeave ?? 12}');
  isAdmin.value = r?.isAdmin ?? false;
}

/// Strips seconds from API time strings like "09:00:00" → "09:00"
String _formatTime(String time) {
  final parts = time.split(':');
  if (parts.length >= 2) {
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }
  return time;
}

  @override
  void dispose() {
    name.dispose();
    // from.dispose();
    // to.dispose();
    // breakTime.dispose();
    permMin.dispose();
    leave.dispose();
    super.dispose();
  }

  Future<void> pickTime(TextEditingController ctrl) async {
    final parts = ctrl.text.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(
      context: Get.context!,
      initialTime: initial,
    );
    if (picked != null) {
      ctrl.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      // Re-validate the whole form so cross-field rules (To > From) update
      formKey.currentState?.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'Edit Designation' : 'Add Designation',
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

            // ── Body ─────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                child: Obx(
                  () => Form(
                    key: formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          ResponsiveGridRow(
                            children: List.generate(fields.length, (ind) {
                              return ResponsiveGridCol(
                                xl: fields[ind]["xl"] ?? 12,
                                lg: fields[ind]["lg"] ?? 12,
                                md: fields[ind]["md"] ?? 12,
                                xs: fields[ind]["xs"] ?? 12,
                                sm: fields[ind]["sm"] ?? 12,
                                child: FormFields(
                                  label: fields[ind]["label"] ?? "",
                                  type: fields[ind]["type"] ?? "",
                                  textEditingController:
                                      fields[ind]["controller"],
                                  obscureText: fields[ind]["obscureText"],
                                  prefixIcon: fields[ind]["prefixIcon"],
                                  suffixIcon: fields[ind]["suffixIcon"],
                                  switchValue: fields[ind]["switchValue"],
                                  onSwitchChanged:
                                      fields[ind]["onSwitchChanged"],
                                  onSuffixTap: fields[ind]["onSuffixTap"],
                                  validator: fields[ind]["validator"],
                                  keyboardType: fields[ind]["keyboardType"],
                                  onPressed: fields[ind]["onPressed"],
                                  onTap: fields[ind]["onTap"],
                                  isLoading: fields[ind]["isLoading"],
                                  readOnly: fields[ind]["readOnly"],
                                  isFullWidth: fields[ind]["isFullWidth"],
                                  topPadding: fields[ind]["topPadding"],
                                  bottomPadding: fields[ind]["bottomPadding"],
                                  rightPadding: fields[ind]["rightPadding"],
                                  leftPadding: fields[ind]["leftPadding"],
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: SriButton(
                                  label: "Cancel",
                                  isOutlined: true,
                                  onPressed: () => Get.back(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SriButton(
                                  label: isEdit ? "Update" : "Create",
                                  onPressed: () {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    final data = {
                                      'company_id': auth.companyId,
                                      'name': name.text.trim(),
                                      // 'working_from': from.text,
                                      // 'working_to': to.text,
                                      // 'break_minutes':
                                      //     int.tryParse(breakTime.text) ?? 30,
                                      'permission_minutes':
                                          int.tryParse(permMin.text) ?? 60,
                                      'casual_leave':
                                          int.tryParse(leave.text) ?? 12,
                                      'is_admin': isAdmin.value,
                                    };
                                    if (isEdit) {
                                      widget.controller.updateRole(
                                        widget.role.id,
                                        data,
                                      );
                                    } else {
                                      widget.controller.createRole(data);
                                    }
                                    Get.back();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}