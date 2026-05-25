import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/department/controller/department_controller.dart';
import 'package:sri_hr/widgets/form_fields.dart';
import 'package:sri_hr/widgets/sri_button.dart';

class DepartmentForm extends StatefulWidget {
  final dynamic dept;
  final DepartmentController controller;
  const DepartmentForm({super.key, this.dept, required this.controller});

  @override
  State<DepartmentForm> createState() => _DepartmentFormState();
}

class _DepartmentFormState extends State<DepartmentForm> {
  final formKey = GlobalKey<FormState>();

  final TextEditingController codeCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();

  bool get isEdit => widget.dept != null;
  String? get _editId => isEdit ? widget.dept.id as String? : null;

  String? _validateCode(String? v) {
    if (v == null || v.trim().isEmpty) return 'Department Code is required';
    final trimmed = v.trim();
    if (trimmed.length < 2) return 'Code must be at least 2 characters';
    if (trimmed.length > 10) return 'Code must not exceed 10 characters';
    if (!RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(trimmed)) {
      return 'Only letters, numbers, hyphens and underscores allowed';
    }
    if (widget.controller.isDuplicateCode(trimmed, excludeId: _editId)) {
      return '"${trimmed.toUpperCase()}" already exists. Please use a unique code.';
    }
    return null;
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Department Name is required';
    final trimmed = v.trim();
    if (trimmed.length < 2) return 'Name must be at least 2 characters';
    if (trimmed.length > 50) return 'Name must not exceed 50 characters';
    if (widget.controller.isDuplicateName(trimmed, excludeId: _editId)) {
      return '"$trimmed" already exists. Please use a unique name.';
    }
    return null;
  }

  bool outsideAtt = false;
  bool mobileLogin = false;

  @override
  void initState() {
    super.initState();

    codeCtrl.text = widget.dept?.code ?? '';
    nameCtrl.text = widget.dept?.name ?? '';

    mobileLogin = widget.dept?.mobileLogin ?? true;
    outsideAtt = widget.dept?.outsideAttendance ?? false;
  }

  List<dynamic> get fields => [
    {
      "label": "Department Code",
      "controller": codeCtrl,
      "type": "text",
      "keyboardType": TextInputType.text,
      "prefixIcon": Icons.tag,
      "validator": (v) => _validateCode(v as String?),
    },
    {
      "label": "Department Name",
      "controller": nameCtrl,
      "type": "text",
      "keyboardType": TextInputType.text,
      "prefixIcon": Icons.account_tree_outlined,
      "validator": (v) => _validateName(v as String?),
      "topPadding": 16.0,
    },
    {
      "label": "Mobile Login",
      "hint": "Allow employees to login via mobile app",
      "type": "switch",
      "switchValue": mobileLogin,
      "onSwitchChanged": (v) {
        return setState(() {
          mobileLogin = v;
        });
      },
      "topPadding": 16.0,
    },
    {
      "label": "Outside Attendance",
      "hint": "Allow attendance from outside office location",
      "type": "switch",
      "switchValue": outsideAtt,
      "onSwitchChanged": (v) {
        return setState(() {
          outsideAtt = v;
        });
      },
      "topPadding": 16.0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
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
                  const Icon(Icons.account_tree_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    widget.dept == null ? 'Add Department' : 'Edit Department',
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
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveGridRow(
                          children: [
                            ...List.generate(fields.length, (index) {
                              return ResponsiveGridCol(
                                xl: fields[index]["xl"] ?? 12,
                                lg: fields[index]["lg"] ?? 12,
                                md: fields[index]["md"] ?? 12,
                                xs: fields[index]["xs"] ?? 12,
                                sm: fields[index]["sm"] ?? 12,
                                child: FormFields(
                                  label: fields[index]["label"] ?? "",
                                  type: fields[index]["type"] ?? "",
                                  textEditingController:
                                      fields[index]["controller"],
                                  obscureText: fields[index]["obscureText"],
                                  prefixIcon: fields[index]["prefixIcon"],
                                  suffixIcon: fields[index]["suffixIcon"],
                                  onSuffixTap: fields[index]["onSuffixTap"],
                                  validator: fields[index]["validator"],
                                  hint: fields[index]["hint"],
                                  switchValue: fields[index]["switchValue"],
                                  onSwitchChanged:
                                      fields[index]["onSwitchChanged"],
                                  keyboardType: fields[index]["keyboardType"],
                                  onPressed: fields[index]["onPressed"],
                                  isLoading: fields[index]["isLoading"],
                                  isFullWidth: fields[index]["isFullWidth"],
                                  topPadding: fields[index]["topPadding"],
                                  bottomPadding: fields[index]["bottomPadding"],
                                  rightPadding: fields[index]["rightPadding"],
                                  leftPadding: fields[index]["leftPadding"],
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
                                onPressed: () => Get.back(),
                                isOutlined: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SriButton(
                                label: widget.dept == null
                                    ? "Create"
                                    : "Update",
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }
                                  final data = {
                                    'company_id':
                                        Get.find<AuthController>().companyId,
                                    'code': codeCtrl.text.trim().toUpperCase(),
                                    'name': nameCtrl.text.trim(),
                                    'mobile_login': mobileLogin,
                                    'outside_attendance': outsideAtt,
                                  };
                                  if (widget.dept == null) {
                                    widget.controller.create(data);
                                  } else {
                                    widget.controller.updateDepartment(
                                      widget.dept.id,
                                      data,
                                    );
                                  }

                                  Get.back();
                                  Future.delayed(Duration(seconds: 2), () {
                                    widget.controller.loadDepartments();
                                  });
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
          ],
        ),
      ),
    );
  }
}
