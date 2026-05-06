import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/salary_type/controller/salary_type_controller.dart';
import 'package:sri_hr/widgets/form_fields.dart';
import 'package:sri_hr/widgets/sri_button.dart';

class SalaryTypeForm extends StatefulWidget {
  final dynamic item;
  final SalaryTypeController controller;
  const SalaryTypeForm({super.key, required this.controller, this.item});

  @override
  State<SalaryTypeForm> createState() => _SalaryTypeFormState();
}

class _SalaryTypeFormState extends State<SalaryTypeForm> {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameCtrl.text = widget.item?.name ?? '';
  }

  List<dynamic> get fields => [
    {
      "label": "Salary Type",
      "controller": nameCtrl,
      "type": "text",
      "keyboardType": TextInputType.text,
      "topPadding": 20.0,
      "validator": (v) {
        if (v.isEmpty) {
          return "Salary Type is required";
        }
        return null;
      },
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
            decoration: BoxDecoration(
              color: AppColors.accentOrange,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.payments_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  widget.item == null ? 'Add Salary Type' : 'Edit Salary Type',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Get.back();
                  },
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                            textEditingController: fields[index]["controller"],
                            obscureText: fields[index]["obscureText"],
                            prefixIcon: fields[index]["prefixIcon"],
                            suffixIcon: fields[index]["suffixIcon"],
                            onSuffixTap: fields[index]["onSuffixTap"],
                            validator: fields[index]["validator"],
                            hint: fields[index]["hint"],
                            switchValue: fields[index]["switchValue"],
                            onSwitchChanged: fields[index]["onSwitchChanged"],
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
                          onPressed: () {
                            Get.back();
                          },
                          isOutlined: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SriButton(
                          label: widget.item == null ? "Create" : "Update",
                          color: AppColors.accentOrange,
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            if (widget.item == null) {
                              widget.controller.create(nameCtrl.text.trim());
                            } else {
                              widget.controller.updateSalaryType(
                                widget.item.id,
                                nameCtrl.text.trim(),
                              );
                            }
                            Get.back();
                            Future.delayed(Duration(seconds: 2), () {
                              widget.controller.load();
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
        ],
      ),
    );
  }
}
