import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_grid/responsive_grid.dart';
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

  // ── Duplicate-check state ────────────────────────────────
  Timer? _nameDebounce;
  Timer? _codeDebounce;
  Timer? _gstinDebounce;
  Timer? _phoneDebounce;
  Timer? _emailDebounce;

  bool isCheckingName = false;
  bool isCheckingCode = false;
  bool isCheckingGstin = false;
  bool isCheckingPhone = false;
  bool isCheckingEmail = false;

  String? nameError;
  String? codeError;
  String? gstinError;
  String? phoneError;
  String? emailError;

  // ── Helpers ──────────────────────────────────────────────

  bool get _anyChecking =>
      isCheckingName ||
      isCheckingCode ||
      isCheckingGstin ||
      isCheckingPhone ||
      isCheckingEmail;

  bool get _hasErrors =>
      nameError != null ||
      codeError != null ||
      gstinError != null ||
      phoneError != null ||
      emailError != null;

  void _debounce(
    Timer? timer,
    void Function(Timer t) setter,
    VoidCallback action,
  ) {
    timer?.cancel();
    setter(Timer(const Duration(milliseconds: 600), action));
  }

  // ── Field change handlers ────────────────────────────────

  void onNameChanged(String value) {
    _nameDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        nameError = null;
        isCheckingName = false;
      });
      return;
    }
    setState(() {
      isCheckingName = true;
      nameError = null;
    });
    _nameDebounce = Timer(const Duration(milliseconds: 600), () async {
      final exists = await widget.controller.isBranchNameExists(value.trim());
      if (!mounted) return;
      setState(() {
        isCheckingName = false;
        nameError = exists ? 'Branch name already exists' : null;
      });
    });
  }

  void onCodeChanged(String value) {
    _codeDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        codeError = null;
        isCheckingCode = false;
      });
      return;
    }
    setState(() {
      isCheckingCode = true;
      codeError = null;
    });
    _codeDebounce = Timer(const Duration(milliseconds: 600), () async {
      final exists = await widget.controller.isBranchCodeExists(value.trim());
      if (!mounted) return;
      setState(() {
        isCheckingCode = false;
        codeError = exists ? 'Branch code already exists' : null;
      });
    });
  }

  void onGstinChanged(String value) {
    _gstinDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        gstinError = null;
        isCheckingGstin = false;
      });
      return;
    }
    setState(() {
      isCheckingGstin = true;
      gstinError = null;
    });
    _gstinDebounce = Timer(const Duration(milliseconds: 600), () async {
      final exists = await widget.controller.isGstinExists(value.trim());
      if (!mounted) return;
      setState(() {
        isCheckingGstin = false;
        gstinError = exists ? 'GSTIN already registered' : null;
      });
    });
  }

  static bool _isValidPhone(String v) =>
      RegExp(r'^[0-9]{10}$').hasMatch(v.trim());

  static bool _isValidEmail(String v) =>
      RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(v.trim());

  void onPhoneChanged(String value) {
    _phoneDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        phoneError = null;
        isCheckingPhone = false;
      });
      return;
    }
    // Format check first — no API call needed
    if (!_isValidPhone(value)) {
      setState(() {
        phoneError = 'Phone number must be 10 digits';
        isCheckingPhone = false;
      });
      return;
    }
    setState(() {
      isCheckingPhone = true;
      phoneError = null;
    });
    _phoneDebounce = Timer(const Duration(milliseconds: 600), () async {
      final exists = await widget.controller.isPhoneGloballyExists(value.trim());
      if (!mounted) return;
      setState(() {
        isCheckingPhone = false;
        phoneError = exists ? 'Phone number already registered' : null;
      });
    });
  }

  void onEmailChanged(String value) {
    _emailDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        emailError = null;
        isCheckingEmail = false;
      });
      return;
    }
    // Format check first — no API call needed
    if (!_isValidEmail(value)) {
      setState(() {
        emailError = 'Enter a valid email address';
        isCheckingEmail = false;
      });
      return;
    }
    setState(() {
      isCheckingEmail = true;
      emailError = null;
    });
    _emailDebounce = Timer(const Duration(milliseconds: 600), () async {
      final exists =
          await widget.controller.isEmailGloballyExists(value.trim());
      if (!mounted) return;
      setState(() {
        isCheckingEmail = false;
        emailError = exists ? 'Email already registered' : null;
      });
    });
  }

  @override
  void dispose() {
    _nameDebounce?.cancel();
    _codeDebounce?.cancel();
    _gstinDebounce?.cancel();
    _phoneDebounce?.cancel();
    _emailDebounce?.cancel();
    name.dispose();
    code.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
    country.dispose();
    state.dispose();
    city.dispose();
    pincode.dispose();
    gstin.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 500;
    return SafeArea(
      top: false,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 620),
        child: Column(
          children: [
            // Header
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

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      ResponsiveGridRow(
                        children: [
                          // Branch Name
                          ResponsiveGridCol(
                            xl: 6, lg: 6, md: 6, xs: 12, sm: 12,
                            child: Padding(
                              padding:
                                  EdgeInsets.only(right: isWide ? 5.0 : 0.0),
                              child: _fieldWithStatus(
                                child: SriTextField(
                                  controller: name,
                                  label: 'Branch Name *',
                                  prefixIcon: Icons.business_rounded,
                                  onChanged: onNameChanged,
                                  suffixIconWidget:
                                      _statusIcon(isCheckingName, nameError, name),
                                  validator: (v) {
                                    if (v?.isEmpty == true) {
                                      return 'Branch Name is Required';
                                    }
                                    if (isCheckingName) {
                                      return 'Checking name...';
                                    }
                                    return nameError;
                                  },
                                ),
                                errorText: nameError,
                                checking: isCheckingName,
                                controller: name,
                              ),
                            ),
                          ),

                          // Branch Code
                          ResponsiveGridCol(
                            xl: 6, lg: 6, md: 6, xs: 12, sm: 12,
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: isWide ? 5.0 : 0.0,
                                top: isWide ? 0.0 : 20.0,
                              ),
                              child: _fieldWithStatus(
                                child: SriTextField(
                                  controller: code,
                                  label: 'Branch Code *',
                                  prefixIcon: Icons.tag_rounded,
                                  hint: 'e.g. BR-01',
                                  onChanged: onCodeChanged,
                                  suffixIconWidget:
                                      _statusIcon(isCheckingCode, codeError, code),
                                  validator: (v) {
                                    if (v?.isEmpty == true) {
                                      return 'Branch Code is Required';
                                    }
                                    if (isCheckingCode) {
                                      return 'Checking code...';
                                    }
                                    return codeError;
                                  },
                                ),
                                errorText: codeError,
                                checking: isCheckingCode,
                                controller: code,
                              ),
                            ),
                          ),

                          // Phone
                          ResponsiveGridCol(
                            xl: 6, lg: 6, md: 6, xs: 12, sm: 12,
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: isWide ? 5.0 : 0.0,
                                top: 20.0,
                              ),
                              child: _fieldWithStatus(
                                child: SriTextField(
                                  controller: phone,
                                  label: 'Phone',
                                  prefixIcon: Icons.phone_rounded,
                                  keyboardType: TextInputType.phone,
                                  onChanged: onPhoneChanged,
                                  suffixIconWidget:
                                      _statusIcon(isCheckingPhone, phoneError, phone),
                                  validator: (_) =>
                                      isCheckingPhone ? 'Checking...' : phoneError,
                                ),
                                errorText: phoneError,
                                checking: isCheckingPhone,
                                controller: phone,
                              ),
                            ),
                          ),

                          // Email
                          ResponsiveGridCol(
                            xl: 6, lg: 6, md: 6, xs: 12, sm: 12,
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: isWide ? 5.0 : 0.0,
                                top: 20.0,
                              ),
                              child: _fieldWithStatus(
                                child: SriTextField(
                                  controller: email,
                                  label: 'Email',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  onChanged: onEmailChanged,
                                  suffixIconWidget:
                                      _statusIcon(isCheckingEmail, emailError, email),
                                  validator: (_) =>
                                      isCheckingEmail ? 'Checking...' : emailError,
                                ),
                                errorText: emailError,
                                checking: isCheckingEmail,
                                controller: email,
                              ),
                            ),
                          ),

                          // GSTIN
                          ResponsiveGridCol(
                            xl: 12, lg: 12, md: 12, xs: 12, sm: 12,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: _fieldWithStatus(
                                child: SriTextField(
                                  controller: gstin,
                                  label: 'GSTIN',
                                  prefixIcon: Icons.numbers_rounded,
                                  onChanged: onGstinChanged,
                                  suffixIconWidget:
                                      _statusIcon(isCheckingGstin, gstinError, gstin),
                                  validator: (_) =>
                                      isCheckingGstin ? 'Checking...' : gstinError,
                                ),
                                errorText: gstinError,
                                checking: isCheckingGstin,
                                controller: gstin,
                              ),
                            ),
                          ),

                          // Address
                          ResponsiveGridCol(
                            xl: 12, lg: 12, md: 12, xs: 12, sm: 12,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: SriTextField(
                                controller: address,
                                label: 'Address',
                                prefixIcon: Icons.home_rounded,
                                maxLines: 2,
                              ),
                            ),
                          ),

                          // Country
                          ResponsiveGridCol(
                            xl: 6, lg: 6, md: 6, xs: 6, sm: 6,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20.0, right: 5.0),
                              child: SriTextField(
                                controller: country,
                                label: 'Country',
                                prefixIcon: Icons.flag_rounded,
                              ),
                            ),
                          ),

                          // State
                          ResponsiveGridCol(
                            xl: 6, lg: 6, md: 6, xs: 6, sm: 6,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20.0, left: 5.0),
                              child: SriTextField(
                                controller: state,
                                label: 'State',
                                prefixIcon: Icons.map_rounded,
                              ),
                            ),
                          ),

                          // City
                          ResponsiveGridCol(
                            xl: 6, lg: 6, md: 6, xs: 6, sm: 6,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20.0, right: 5.0),
                              child: SriTextField(
                                controller: city,
                                label: 'City',
                                prefixIcon: Icons.location_city_rounded,
                              ),
                            ),
                          ),

                          // Pincode
                          ResponsiveGridCol(
                            xl: 6, lg: 6, md: 6, xs: 6, sm: 6,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20.0, left: 5.0),
                              child: SriTextField(
                                controller: pincode,
                                label: 'Pincode',
                                keyboardType: TextInputType.number,
                                prefixIcon: Icons.pin_drop_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer buttons
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
                        label: 'Add Branch',
                        onPressed: (widget.controller.isLoading.value ||
                                _anyChecking ||
                                _hasErrors)
                            ? null
                            : submit,
                        isLoading: widget.controller.isLoading.value,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Suffix icon: spinner / error / checkmark ─────────────
  Widget? _statusIcon(
    bool checking,
    String? error,
    TextEditingController ctrl,
  ) {
    if (checking) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (ctrl.text.isNotEmpty) {
      if (error != null) {
        return const Icon(Icons.cancel_rounded, color: Colors.red, size: 18);
      }
      return const Icon(
        Icons.check_circle_rounded,
        color: AppColors.accentGreen,
        size: 18,
      );
    }
    return null;
  }

  // ── Inline status text below field ───────────────────────
  Widget _fieldWithStatus({
    required Widget child,
    required String? errorText,
    required bool checking,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        if (errorText != null && !checking) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 11),
            ),
          ),
        ] else if (!checking &&
            errorText == null &&
            controller.text.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              'Available ✓',
              style: const TextStyle(
                color: AppColors.accentGreen,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Submit ───────────────────────────────────────────────
  void submit() {
    if (!formKey.currentState!.validate()) return;
    if (_anyChecking) {
      Get.snackbar(
        'Please Wait',
        'Checking for duplicates...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
      );
      return;
    }
    if (_hasErrors) return;

    widget.controller.addBranch({
      'name': name.text.trim().isEmpty ? null : name.text.trim(),
      'branch_code': code.text.trim().isEmpty ? null : code.text.trim(),
      'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
      'email': email.text.trim().isEmpty ? null : email.text.trim(),
      'gstin': gstin.text.trim().isEmpty ? null : gstin.text.trim(),
      'address': address.text.trim().isEmpty ? null : address.text.trim(),
      'country': country.text.trim().isEmpty ? null : country.text.trim(),
      'state': state.text.trim().isEmpty ? null : state.text.trim(),
      'city': city.text.trim().isEmpty ? null : city.text.trim(),
      'pincode': pincode.text.trim().isEmpty ? null : pincode.text.trim(),
    });
    Get.back();
  }
}