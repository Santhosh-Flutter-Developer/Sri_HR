import 'dart:developer';

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

  List<dynamic> get fields => [
    {
      "label": "Role Name",
      "controller": name,
      "type": "text",
      "keyboardType": TextInputType.text,
      "prefixIcon": Icons.badge_outlined,
      "validator": (v) => v!.isEmpty ? "Role Name is required" : null,
      "bottomPadding": 24.0,
    },

    {
      "label": "From Time",
      "controller": from,
      "type": "text",
      "keyboardType": TextInputType.text,
      "readOnly": true,
      "prefixIcon": Icons.schedule,
      "onTap": () => pickTime(from),
      "validator": (v) => v!.isEmpty ? 'From Time is required' : null,
      "xl": 6,
      "lg": 6,
      "md": 6,
      "xs": 6,
      "sm": 6,
    },
    {
      "label": "To Time",
      "controller": to,
      "type": "text",
      "keyboardType": TextInputType.text,
      "prefixIcon": Icons.schedule,
      "readOnly": true,
      "onTap": () => pickTime(to),
      "validator": (v) => v!.isEmpty ? 'To Time is required' : null,
      "leftPadding": 8.0,
      "xl": 6,
      "lg": 6,
      "md": 6,
      "xs": 6,
      "sm": 6,
    },
    {
      "label": "Break Time (mins)",
      "controller": breakTime,
      "type": "text",
      "prefixIcon": Icons.coffee_outlined,
      "keyboardType": TextInputType.number,
      "validator": (v) => v!.isEmpty ? 'Break Time is required' : null,
      "topPadding": 16.0,
      "xl": 6,
      "lg": 6,
      "md": 6,
      "xs": 6,
      "sm": 6,
    },
    {
      "label": "Permission (mins)",
      "controller": permMin,
      "type": "text",
      "keyboardType": TextInputType.number,
      "prefixIcon": Icons.timelapse_outlined,
      "validator": (v) => v!.isEmpty ? 'Permission is required' : null,
      "leftPadding": 8.0,
      "topPadding": 16.0,
      "xl": 6,
      "lg": 6,
      "md": 6,
      "xs": 6,
      "sm": 6,
    },
    {
      "label": "Casual Leave (days)",
      "controller": leave,
      "type": "text",
      "prefixIcon": Icons.event_available_outlined,
      "keyboardType": TextInputType.number,
      "validator": (v) => v!.isEmpty ? 'Casual Leave is required' : null,
      "topPadding": 16.0,
    },
    {
      "label": "Admin Role",

      "type": "switch",
      "switchValue": isAdmin.value,
      "onSwitchChanged": (v) {
        return isAdmin.value = v;
      },
      "topPadding": 16.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.role;
    name = TextEditingController(text: r?.name ?? '');
    from = TextEditingController(text: r?.workingFrom ?? '09:00');
    to = TextEditingController(text: r?.workingTo ?? '18:00');
    breakTime = TextEditingController(text: '${r?.breakMinutes ?? 30}');
    permMin = TextEditingController(text: '${r?.permissionMinutes ?? 60}');
    leave = TextEditingController(text: '${r?.casualLeave ?? 12}');
    isAdmin.value = r?.isAdmin ?? false;
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Obx(
              () => Form(
                key: formKey,
                child: Column(
                  children: [
                    ResponsiveGridRow(
                      children: [
                        ...List.generate(fields.length, (ind) {
                          return ResponsiveGridCol(
                            xl: fields[ind]["xl"] ?? 12,
                            lg: fields[ind]["lg"] ?? 12,
                            md: fields[ind]["md"] ?? 12,
                            xs: fields[ind]["xs"] ?? 12,
                            sm: fields[ind]["sm"] ?? 12,
                            child: FormFields(
                              label: fields[ind]["label"] ?? "",
                              type: fields[ind]["type"] ?? "",
                              textEditingController: fields[ind]["controller"],
                              obscureText: fields[ind]["obscureText"],
                              prefixIcon: fields[ind]["prefixIcon"],
                              suffixIcon: fields[ind]["suffixIcon"],
                              switchValue: fields[ind]["switchValue"],
                              onSwitchChanged: fields[ind]["onSwitchChanged"],
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
                      ],
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
                              if (!formKey.currentState!.validate()) return;
                              final data = {
                                'company_id': auth.companyId,
                                'name': name.text.trim(),
                                'working_from': from.text,
                                'working_to': to.text,
                                'break_minutes':
                                    int.tryParse(breakTime.text) ?? 30,
                                'permission_minutes':
                                    int.tryParse(permMin.text) ?? 60,
                                'casual_leave': int.tryParse(leave.text) ?? 12,
                                'is_admin': isAdmin.value,
                              };
                              log("data:$data");
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
        ],
      ),
    );
  }
}
