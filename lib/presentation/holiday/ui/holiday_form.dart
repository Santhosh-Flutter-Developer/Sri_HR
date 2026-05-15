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

  @override
  void initState() {
    super.initState();
    NetworkTime.syncTime();
    dateCtrl.text = widget.item != null
        ? DateFormat('dd-MM-yyyy').format(widget.item?.date)
        : '';
    reasonCtrl.text = widget.item?.reason ?? '';
    daysCtrl.text = '${widget.item?.days ?? 1}';
  }

  List<dynamic> get fields => [
    {
      "label": "Date",
      "type": "date",
      "controller": dateCtrl,
      "keyboardType": TextInputType.text,
      "prefixIcon": Icons.calendar_today_outlined,
      "readOnly": true,
      "onTapDate": (val) {
        dateCtrl.text = DateFormat('yyyy-MM-dd').format(val);
      },
      "validator": (v) => v!.isEmpty ? "Date is required" : null,
    },
    {
      "label": "Reason",
      "controller": reasonCtrl,
      "type": "text",
      "keyboardType": TextInputType.text,
      "prefixIcon": Icons.info_outline,
      "topPadding": 20.0,
      "validator": (v) {
        if (v.isEmpty) {
          return "Reason is required";
        }
        return null;
      },
    },
    {
      "label": "No. of Days",
      "controller": daysCtrl,
      "type": "text",
      "keyboardType": TextInputType.text,
      "prefixIcon": Icons.date_range_outlined,
      "topPadding": 20.0,
      "validator": (v) {
        if (v.isEmpty) {
          return "No. of Days is required";
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
              color: AppColors.accent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.celebration_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  widget.item == null
                      ? 'Add Holiday Entry'
                      : 'Edit Holiday Entry',
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
                            onTapDate: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: NetworkTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                final function = fields[index]["onTapDate"];

                                if (function != null) {
                                  function(date);
                                }
                              }
                            },
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
                          onPressed: () => Get.back(),
                          isOutlined: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SriButton(
                          label: widget.item == null ? "Add" : "Update",
                          color: AppColors.accent,
                          onPressed: () {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }
                            final data = {
                              'date': dateCtrl.text,
                              'reason': reasonCtrl.text,
                              'days': int.tryParse(daysCtrl.text) ?? 1,
                            };
                            if (widget.item == null) {
                              widget.controller.create(data);
                            } else {
                              widget.controller.updateHoliday(
                                widget.item.id,
                                data,
                              );
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
        ],
      ),
    );
  }
}
