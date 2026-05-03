import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/company/controller/company_controller.dart';
import 'package:sri_hr/widgets/sri_button.dart';
import 'package:sri_hr/widgets/sri_textfield.dart';

class AddBranchForm extends StatefulWidget {
  final CompanyController controller;
  const AddBranchForm({super.key, required this.controller});

  @override
  State<AddBranchForm> createState() => _AddBranchFormState();
}

class _AddBranchFormState extends State<AddBranchForm> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final code = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final country = TextEditingController(text: 'India');
  final state = TextEditingController();
  final city = TextEditingController();
  final pincode = TextEditingController();
  final gstin = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 580, maxHeight: 620),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B5BDB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.add_business_rounded, color: Colors.white),
                const SizedBox(width: 10),
                const Text(
                  'Add New Branch',
                  style: TextStyle(
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SriTextField(
                            controller: name,
                            label: 'Branch Name *',
                            prefixIcon: Icons.business_rounded,
                            validator: (v) =>
                                v?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SriTextField(
                            controller: code,
                            label: 'Branch Code',
                            prefixIcon: Icons.tag_rounded,
                            hint: 'e.g. BR-01',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SriTextField(
                            controller: phone,
                            label: 'Phone',
                            prefixIcon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SriTextField(
                            controller: email,
                            label: 'Email',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SriTextField(
                      controller: gstin,
                      label: 'GSTIN',
                      prefixIcon: Icons.numbers_rounded,
                    ),
                    const SizedBox(height: 14),
                    SriTextField(
                      controller: address,
                      label: 'Address',
                      prefixIcon: Icons.home_rounded,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SriTextField(
                            controller: country,
                            label: 'Country',
                            prefixIcon: Icons.flag_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SriTextField(
                            controller: state,
                            label: 'State',
                            prefixIcon: Icons.map_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SriTextField(
                            controller: city,
                            label: 'City',
                            prefixIcon: Icons.location_city_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SriTextField(
                            controller: pincode,
                            label: 'Pincode',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.pin_drop_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SriButton(
                    label: 'Cancel',
                    onPressed: () => Get.back(),
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(
                    () => SriButton(
                      label: "Add Branch",
                      onPressed: widget.controller.isLoading.value
                          ? null
                          : submit,
                      icon: Icons.add_business_rounded,
                      isLoading: widget.controller.isLoading.value,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void submit() {
    if (!formKey.currentState!.validate()) return;
    widget.controller.addBranch({
      'name': name.text.trim(),
      'branch_code': code.text.trim().isEmpty ? null : code.text.trim(),
      'phone': phone.text.trim(),
      'email': email.text.trim(),
      'gstin': gstin.text.trim(),
      'address': address.text.trim(),
      'country': country.text.trim(),
      'state': state.text.trim(),
      'city': city.text.trim(),
      'pincode': pincode.text.trim(),
    });
    Get.back();
  }
}
