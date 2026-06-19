import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/company_model.dart';
import 'package:sri_hr/presentation/company/controller/company_controller.dart';
import 'package:sri_hr/presentation/company/widgets/sri_detail_card.dart';
import 'package:sri_hr/presentation/company/widgets/work_shift_card.dart';
import 'package:sri_hr/widgets/sri_button.dart';
import 'package:sri_hr/widgets/sri_textfield.dart';

// ── Duplicate-check mixin helpers (reused inline) ────────────────────────────

class CompanyDetail extends StatefulWidget {
  final CompanyModel company;
  final CompanyController controller;
  final bool canEdit;
  const CompanyDetail({
    super.key,
    required this.company,
    required this.controller,
    required this.canEdit,
  });

  @override
  State<CompanyDetail> createState() => _CompanyDetailState();
}

class _CompanyDetailState extends State<CompanyDetail> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController name,
      phone,
      email,
      address,
      country,
      state,
      city,
      pincode,
      gstin,
      branchCode,
      lat,
      lon,
      radius;
  bool editing = false;
  Uint8List? logoBytes;
  String? logoPath;

  // Key to trigger shift save from this parent
  final _workShiftKey = GlobalKey<WorkShiftCardState>();

  // ── Kiosk / Without-Login settings ──────────────────────
  late bool kioskEnabled; // Without Login: true/false
  late String notifLang; // 'en' or 'ta'
  final kioskUsernameCtrl = TextEditingController();
  final kioskPasswordCtrl = TextEditingController();
  bool kioskPasswordVisible = false;

  // Live username uniqueness check
  Timer? _usernameDebounce;
  bool isCheckingUsername = false;
  bool usernameVerified = false;
  String? usernameError;

  // Live password validation
  String? passwordError;

  // ── Duplicate-check state for branch fields ──────────────
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
  String? editEmailError;

  bool get _anyFieldChecking =>
      isCheckingName ||
      isCheckingCode ||
      isCheckingGstin ||
      isCheckingPhone ||
      isCheckingEmail;

  bool get _hasFieldErrors =>
      nameError != null ||
      codeError != null ||
      gstinError != null ||
      phoneError != null ||
      editEmailError != null;

  @override
  void initState() {
    super.initState();
    init(widget.company);
    kioskEnabled = widget.company.withoutLoginEnabled;
    notifLang = widget.company.notificationLanguage;
    // Preserve exact case as stored
    kioskUsernameCtrl.text = widget.company.kioskUsername ?? '';
    // Existing saved username is already valid
    usernameVerified = widget.company.kioskUsername != null;
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _nameDebounce?.cancel();
    _codeDebounce?.cancel();
    _gstinDebounce?.cancel();
    _phoneDebounce?.cancel();
    _emailDebounce?.cancel();
    kioskUsernameCtrl.dispose();
    kioskPasswordCtrl.dispose();
    super.dispose();
  }

  void init(CompanyModel c) {
    name = TextEditingController(text: c.name);
    phone = TextEditingController(text: c.phone ?? '');
    email = TextEditingController(text: c.email ?? '');
    address = TextEditingController(text: c.address ?? '');
    country = TextEditingController(text: c.country ?? '');
    state = TextEditingController(text: c.state ?? '');
    city = TextEditingController(text: c.city ?? '');
    pincode = TextEditingController(text: c.pincode ?? '');
    gstin = TextEditingController(text: c.gstin ?? '');
    branchCode = TextEditingController(text: c.branchCode ?? '');
    lat = TextEditingController(text: '${c.latitude ?? ''}');
    lon = TextEditingController(text: '${c.longitude ?? ''}');
    radius = TextEditingController(text: '${c.radius}');
  }

  bool get isUsernameChanged {
    final originalUsername = widget.company.kioskUsername ?? '';
    final currentUsername = kioskUsernameCtrl.text.trim();

    return widget.company.kioskUsername != null &&
        currentUsername != originalUsername;
  }

  // ── Duplicate-check handlers for branch fields ──────────

  void onNameChanged(String value) {
    _nameDebounce?.cancel();
    if (value.trim().isEmpty ||
        value.trim().toLowerCase() == widget.company.name.toLowerCase()) {
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
      final exists = await widget.controller.isBranchNameExists(
        value.trim(),
        excludeCompanyId: widget.company.id,
      );
      if (!mounted) return;
      setState(() {
        isCheckingName = false;
        nameError = exists ? 'Branch name already exists' : null;
      });
    });
  }

  void onCodeChanged(String value) {
    _codeDebounce?.cancel();
    if (value.trim().isEmpty ||
        value.trim().toLowerCase() ==
            (widget.company.branchCode ?? '').toLowerCase()) {
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
      final exists = await widget.controller.isBranchCodeExists(
        value.trim(),
        excludeCompanyId: widget.company.id,
      );
      if (!mounted) return;
      setState(() {
        isCheckingCode = false;
        codeError = exists ? 'Branch code already exists' : null;
      });
    });
  }

  void onGstinChanged(String value) {
    _gstinDebounce?.cancel();
    if (value.trim().isEmpty ||
        value.trim().toLowerCase() ==
            (widget.company.gstin ?? '').toLowerCase()) {
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
      final exists = await widget.controller.isGstinExists(
        value.trim(),
        excludeCompanyId: widget.company.id,
      );
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
    if (value.trim().isEmpty || value.trim() == (widget.company.phone ?? '')) {
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
      final exists = await widget.controller.isPhoneGloballyExists(
        value.trim(),
        excludeCompanyId: widget.company.id,
      );
      if (!mounted) return;
      setState(() {
        isCheckingPhone = false;
        phoneError = exists ? 'Phone number already registered' : null;
      });
    });
  }

  void onEditEmailChanged(String value) {
    _emailDebounce?.cancel();
    if (value.trim().isEmpty ||
        value.trim().toLowerCase() ==
            (widget.company.email ?? '').toLowerCase()) {
      setState(() {
        editEmailError = null;
        isCheckingEmail = false;
      });
      return;
    }
    // Format check first — no API call needed
    if (!_isValidEmail(value)) {
      setState(() {
        editEmailError = 'Enter a valid email address';
        isCheckingEmail = false;
      });
      return;
    }
    setState(() {
      isCheckingEmail = true;
      editEmailError = null;
    });
    _emailDebounce = Timer(const Duration(milliseconds: 600), () async {
      final exists = await widget.controller.isEmailGloballyExists(
        value.trim(),
        excludeCompanyId: widget.company.id,
      );
      if (!mounted) return;
      setState(() {
        isCheckingEmail = false;
        editEmailError = exists ? 'Email already registered' : null;
      });
    });
  }

  // ── Live username check (debounced 600ms) ────────────────
  void onUsernameChanged(String value) {
    _usernameDebounce?.cancel();

    setState(() {
      usernameVerified = false;
    });

    if (value.isEmpty) {
      setState(() {
        usernameError = null;
        isCheckingUsername = false;
      });
      return;
    }

    if (value.contains(' ')) {
      setState(() {
        usernameError = 'Username cannot contain spaces';
        isCheckingUsername = false;
      });
      return;
    }

    // Username unchanged
    if (value.trim() == (widget.company.kioskUsername ?? '')) {
      setState(() {
        usernameError = null;
        isCheckingUsername = false;
        usernameVerified = true;
      });
      return;
    }

    setState(() {
      isCheckingUsername = true;
      usernameError = null;
    });

    _usernameDebounce = Timer(const Duration(milliseconds: 600), () async {
      final available = await widget.controller.isKioskUsernameAvailable(
        value.trim(),
        widget.company.id,
      );

      if (!mounted) return;

      setState(() {
        isCheckingUsername = false;

        if (available) {
          usernameError = null;
          usernameVerified = true;
        } else {
          usernameError = 'This username is already taken';
          usernameVerified = false;
        }
      });
    });
  }

  // ── Live password validation ──────────────────────────────
  void onPasswordChanged(String value) {
    final hasExisting = widget.company.kioskUsername != null;
    setState(() {
      if (value.isEmpty && hasExisting) {
        // Blank = keep existing password → valid
        passwordError = null;
      } else if (value.isNotEmpty && value.length < 6) {
        passwordError = 'Password must be at least 6 characters';
      } else {
        passwordError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isWide ? 24.0 : 10.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isWide)
                InkWell(
                  onTap: () {
                    widget.controller.enable.value = false;
                    widget.controller.enable.refresh();
                  },
                  child: const Icon(Icons.arrow_back_ios_rounded),
                ),
              const SizedBox(height: 20.0),
              headerCard(),
              const SizedBox(height: 20.0),
              // ── Basic Information ────────────────────────
              SriDetailCard(
                title: 'Basic Information',
                icon: Icons.info_outline_rounded,
                children: [
                  ResponsiveGridRow(
                    children: [
                      ResponsiveGridCol(
                        xl: 6,
                        lg: 6,
                        md: 6,
                        xs: 12,
                        sm: 12,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 20.0,
                            right: isWide ? 8.0 : 0.0,
                          ),
                          child: _dupField(
                            child: SriTextField(
                              controller: name,
                              label: 'Company Name *',
                              readOnly: !editing,
                              prefixIcon: Icons.business_rounded,
                              onChanged: editing ? onNameChanged : null,
                              suffixIconWidget: editing
                                  ? _dupStatusIcon(
                                      isCheckingName,
                                      nameError,
                                      name,
                                    )
                                  : null,
                              validator: (v) {
                                if (v?.isEmpty == true)
                                  return 'Company Name is Required';
                                if (isCheckingName) return 'Checking...';
                                return nameError;
                              },
                            ),
                            errorText: nameError,
                            checking: isCheckingName,
                            ctrl: name,
                          ),
                        ),
                      ),
                      ResponsiveGridCol(
                        xl: 6,
                        lg: 6,
                        md: 6,
                        xs: 12,
                        sm: 12,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 20.0,
                            left: isWide ? 8.0 : 0.0,
                          ),
                          child: _dupField(
                            child: SriTextField(
                              controller: branchCode,
                              label: 'Branch Code *',
                              readOnly: !editing,
                              prefixIcon: Icons.tag_rounded,
                              onChanged: editing ? onCodeChanged : null,
                              suffixIconWidget: editing
                                  ? _dupStatusIcon(
                                      isCheckingCode,
                                      codeError,
                                      branchCode,
                                    )
                                  : null,
                              validator: (v) {
                                if (v?.isEmpty == true)
                                  return 'Branch Code is Required';
                                if (isCheckingCode) return 'Checking...';
                                return codeError;
                              },
                            ),
                            errorText: codeError,
                            checking: isCheckingCode,
                            ctrl: branchCode,
                          ),
                        ),
                      ),
                      ResponsiveGridCol(
                        xl: 6,
                        lg: 6,
                        md: 6,
                        xs: 12,
                        sm: 12,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 20.0,
                            right: isWide ? 8.0 : 0.0,
                          ),
                          child: _dupField(
                            child: SriTextField(
                              controller: phone,
                              label: 'Phone',
                              readOnly: !editing,
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icons.phone_rounded,
                              onChanged: editing ? onPhoneChanged : null,
                              suffixIconWidget: editing
                                  ? _dupStatusIcon(
                                      isCheckingPhone,
                                      phoneError,
                                      phone,
                                    )
                                  : null,
                              validator: (_) =>
                                  isCheckingPhone ? 'Checking...' : phoneError,
                            ),
                            errorText: phoneError,
                            checking: isCheckingPhone,
                            ctrl: phone,
                          ),
                        ),
                      ),
                      ResponsiveGridCol(
                        xl: 6,
                        lg: 6,
                        md: 6,
                        xs: 12,
                        sm: 12,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 20.0,
                            left: isWide ? 8.0 : 0.0,
                          ),
                          child: _dupField(
                            child: SriTextField(
                              controller: email,
                              label: 'Email',
                              readOnly: !editing,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_outlined,
                              onChanged: editing ? onEditEmailChanged : null,
                              suffixIconWidget: editing
                                  ? _dupStatusIcon(
                                      isCheckingEmail,
                                      editEmailError,
                                      email,
                                    )
                                  : null,
                              validator: (_) => isCheckingEmail
                                  ? 'Checking...'
                                  : editEmailError,
                            ),
                            errorText: editEmailError,
                            checking: isCheckingEmail,
                            ctrl: email,
                          ),
                        ),
                      ),
                      ResponsiveGridCol(
                        xl: 6,
                        lg: 6,
                        md: 6,
                        xs: 12,
                        sm: 12,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 20.0,
                            right: isWide ? 8.0 : 0.0,
                          ),
                          child: _dupField(
                            child: SriTextField(
                              controller: gstin,
                              label: 'GSTIN',
                              readOnly: !editing,
                              prefixIcon: Icons.numbers_rounded,
                              onChanged: editing ? onGstinChanged : null,
                              suffixIconWidget: editing
                                  ? _dupStatusIcon(
                                      isCheckingGstin,
                                      gstinError,
                                      gstin,
                                    )
                                  : null,
                              validator: (_) =>
                                  isCheckingGstin ? 'Checking...' : gstinError,
                            ),
                            errorText: gstinError,
                            checking: isCheckingGstin,
                            ctrl: gstin,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Address ──────────────────────────────────
              SriDetailCard(
                title: 'Address',
                icon: Icons.location_on_rounded,
                children: [
                  ResponsiveGridRow(
                    children: [
                      ResponsiveGridCol(
                        xl: 12,
                        lg: 12,
                        md: 12,
                        xs: 12,
                        sm: 12,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: SriTextField(
                            controller: address,
                            label: 'Full Address',
                            readOnly: !editing,
                            maxLines: 2,
                            prefixIcon: Icons.home_rounded,
                          ),
                        ),
                      ),
                      ResponsiveGridCol(
                        xl: 6,
                        lg: 6,
                        md: 6,
                        xs: 12,
                        sm: 12,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 20.0,
                            right: isWide ? 8.0 : 0.0,
                          ),
                          child: SriTextField(
                            controller: country,
                            label: 'Country',
                            readOnly: !editing,
                            prefixIcon: Icons.flag_rounded,
                          ),
                        ),
                      ),
                      ResponsiveGridCol(
                        xl: 6,
                        lg: 6,
                        md: 6,
                        xs: 12,
                        sm: 12,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 20.0,
                            left: isWide ? 8.0 : 0.0,
                          ),
                          child: SriTextField(
                            controller: state,
                            label: 'State',
                            readOnly: !editing,
                            prefixIcon: Icons.map_rounded,
                          ),
                        ),
                      ),
                      ResponsiveGridCol(
                        xl: 6,
                        lg: 6,
                        md: 6,
                        xs: 12,
                        sm: 12,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 20.0,
                            right: isWide ? 8.0 : 0.0,
                          ),
                          child: SriTextField(
                            controller: city,
                            label: 'City',
                            readOnly: !editing,
                            prefixIcon: Icons.location_city_rounded,
                          ),
                        ),
                      ),
                      ResponsiveGridCol(
                        xl: 6,
                        lg: 6,
                        md: 6,
                        xs: 12,
                        sm: 12,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 20.0,
                            left: isWide ? 8.0 : 0.0,
                          ),
                          child: SriTextField(
                            controller: pincode,
                            label: 'Pincode',
                            readOnly: !editing,
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.pin_drop_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Geo-fencing ──────────────────────────────
              SriDetailCard(
                title: 'Geo-fencing (Attendance)',
                icon: Icons.radar_rounded,
                children: [
                  ResponsiveGridRow(
                    children: [
                      ResponsiveGridCol(
                        xl: 4,
                        lg: 4,
                        md: 4,
                        sm: 12,
                        xs: 12,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 20.0,
                            right: isWide ? 8.0 : 0.0,
                          ),
                          child: SriTextField(
                            controller: lat,
                            label: 'Latitude',
                            readOnly: !editing,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            prefixIcon: Icons.my_location_rounded,
                          ),
                        ),
                      ),
                      ResponsiveGridCol(
                        xl: 4,
                        lg: 4,
                        md: 4,
                        sm: 12,
                        xs: 12,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 20.0,
                            left: isWide ? 8.0 : 0.0,
                          ),
                          child: SriTextField(
                            controller: lon,
                            label: 'Longitude',
                            readOnly: !editing,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            prefixIcon: Icons.location_on_rounded,
                          ),
                        ),
                      ),
                      ResponsiveGridCol(
                        xl: 4,
                        lg: 4,
                        md: 4,
                        sm: 12,
                        xs: 12,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 20.0,
                            left: isWide ? 8.0 : 0.0,
                          ),
                          child: SriTextField(
                            controller: radius,
                            label: 'Radius (m)',
                            readOnly: !editing,
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.circle_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Configure Attendance Access Without Login ─
              _attendanceAccessCard(isWide),
              const SizedBox(height: 16),
              WorkShiftCard(
                key: _workShiftKey,
                companyId: widget.company.id,
                parentEditing: editing,
              ),
              // ── Save / Cancel ────────────────────────────
              if (editing) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SriButton(
                        onPressed: () => setState(() {
                          editing = false;
                          init(widget.company);
                          // Reset kiosk fields to saved values
                          kioskEnabled = widget.company.withoutLoginEnabled;
                          notifLang = widget.company.notificationLanguage;
                          kioskUsernameCtrl.text =
                              widget.company.kioskUsername ?? '';
                          kioskPasswordCtrl.clear();
                          usernameError = null;
                          passwordError = null;
                          usernameVerified =
                              widget.company.kioskUsername != null;
                          // Reset duplicate check state
                          nameError = null;
                          codeError = null;
                          gstinError = null;
                          phoneError = null;
                          editEmailError = null;
                          isCheckingName = false;
                          isCheckingCode = false;
                          isCheckingGstin = false;
                          isCheckingPhone = false;
                          isCheckingEmail = false;
                        }),
                        isOutlined: true,
                        label: 'Cancel',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(
                        () => SriButton(
                          onPressed:
                              (widget.controller.isLoading.value ||
                                  isCheckingUsername ||
                                  _anyFieldChecking ||
                                  _hasFieldErrors)
                              ? null
                              : save,
                          isLoading: widget.controller.isLoading.value,
                          label: 'Save Changes',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main save (company + kiosk + shift together) ─────────────────
  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;

    // Guard: duplicate checks still in progress
    if (_anyFieldChecking) {
      Get.snackbar(
        'Please Wait',
        'Checking for duplicates...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
      );
      return;
    }

    // Guard: duplicate field errors present
    if (_hasFieldErrors) {
      Get.snackbar(
        'Validation Error',
        'Some fields already exist in the system. Please correct the highlighted fields before saving.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return;
    }

    if (kioskEnabled && isCheckingUsername) {
      Get.snackbar(
        'Please Wait',
        'Checking username availability...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
      );
      return;
    }

    if (kioskEnabled &&
        kioskUsernameCtrl.text.trim().isNotEmpty &&
        !usernameVerified) {
      Get.snackbar(
        'Validation Error',
        'Please check the username availability before saving.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return;
    }

    // Block if username has error
    if (kioskEnabled && usernameError != null) {
      Get.snackbar(
        'Validation Error',
        'Please fix the kiosk username error before saving.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return;
    }

    // Block if password has error
    if (kioskEnabled && passwordError != null) {
      Get.snackbar(
        'Validation Error',
        passwordError!,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return;
    }

    // Kiosk username required when enabling for first time
    final username = kioskUsernameCtrl.text.trim();
    final password = kioskPasswordCtrl.text.trim();
    final hasExisting = widget.company.kioskUsername != null;

    if (kioskEnabled && username.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please enter a kiosk username.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return;
    }

    if (kioskEnabled &&
        ((!hasExisting) || isUsernameChanged) &&
        password.isEmpty) {
      Get.snackbar(
        'Validation Error',
        isUsernameChanged
            ? 'A new password is required when changing the kiosk username.'
            : 'Please set a password for the kiosk account.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return;
    }

    // 1. Save basic company fields
    widget.controller.updateCompany(
      {
        'name': name.text.trim().isEmpty ? null : name.text.trim(),
        'branch_code': branchCode.text.trim().isEmpty
            ? null
            : branchCode.text.trim(),
        'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
        'email': email.text.trim().isEmpty ? null : email.text.trim(),
        'gstin': gstin.text.trim().isEmpty ? null : gstin.text.trim(),
        'address': address.text.trim().isEmpty ? null : address.text.trim(),
        'country': country.text.trim().isEmpty ? null : country.text.trim(),
        'state': state.text.trim().isEmpty ? null : state.text.trim(),
        'city': city.text.trim().isEmpty ? null : city.text.trim(),
        'pincode': pincode.text.trim().isEmpty ? null : pincode.text.trim(),
        'latitude': lat.text.trim().isEmpty ? null : double.tryParse(lat.text),
        'longitude': lon.text.trim().isEmpty ? null : double.tryParse(lon.text),
        'radius': radius.text.trim().isEmpty
            ? null
            : int.tryParse(radius.text) ?? 100,
      },
      logoBytes: logoBytes,
      logoPath: logoPath,
    );

    // 2. Save kiosk settings
    widget.controller.saveKioskSettings(
      companyId: widget.company.id,
      withoutLogin: kioskEnabled,
      language: notifLang,
      kioskUsername: kioskEnabled && kioskUsernameCtrl.text.trim().isNotEmpty
          ? kioskUsernameCtrl.text
          : null, // preserve exact case
      kioskPassword: kioskEnabled && password.isNotEmpty ? password : null,
      isFirstTime: !hasExisting,
    );

    // 3. Save work shift
    final shiftOk = await WorkShiftCard.saveViaKey(_workShiftKey);

    if (!mounted) return;

    if (shiftOk) {
      Get.snackbar(
        'Saved',
        'Company settings saved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.accentGreen,
        colorText: Colors.white,
      );
    }

    setState(() => editing = false);
  }

  // ── Duplicate-check helpers ──────────────────────────────

  Widget? _dupStatusIcon(
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

  Widget _dupField({
    required Widget child,
    required String? errorText,
    required bool checking,
    required TextEditingController ctrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        if (errorText != null && !checking && editing) ...[
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
            ctrl.text.isNotEmpty &&
            editing) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: const Text(
              'Available ✓',
              style: TextStyle(
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

  // ── Attendance Access card ───────────────────────────────
  Widget _attendanceAccessCard(bool isWide) {
    return SriDetailCard(
      title: 'Access Without Login',
      icon: Icons.no_accounts_rounded,
      children: [
        const SizedBox(height: 4),

        // ── Without Login radio buttons ──────────────────
        _sectionLabel(
          'Without Login',
          'Allow attendance marking without Supabase login',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _radioOption(
              label: 'Enable',
              value: true,
              groupValue: kioskEnabled,
              onChanged: (v) {
                if (editing) {
                  setState(() {
                    kioskEnabled = v!;
                    if (!kioskEnabled) {
                      kioskUsernameCtrl.clear();
                      kioskPasswordCtrl.clear();
                      usernameError = null;
                      passwordError = null;
                    }
                  });
                }
              },
            ),
            const SizedBox(width: 24),
            _radioOption(
              label: 'Disable',
              value: false,
              groupValue: kioskEnabled,
              onChanged: (v) {
                if (editing) {
                  setState(() {
                    kioskEnabled = v!;
                    kioskUsernameCtrl.clear();
                    kioskPasswordCtrl.clear();
                    usernameError = null;
                    passwordError = null;
                  });
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 20),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 20),

        // ── Notification Language radio buttons ──────────
        _sectionLabel(
          'Notification Language',
          'Language used for attendance notifications',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _radioOption<String>(
              label: 'English',
              value: 'en',
              groupValue: notifLang,
              onChanged: (v) {
                if (editing) {
                  setState(() => notifLang = v!);
                }
              },
            ),
            const SizedBox(width: 24),
            _radioOption<String>(
              label: 'Tamil (தமிழ்)',
              value: 'ta',
              groupValue: notifLang,
              onChanged: (v) {
                if (editing) {
                  setState(() => notifLang = v!);
                }
              },
            ),
          ],
        ),

        // ── Kiosk credentials (only when enabled) ────────
        if (kioskEnabled) ...[
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          _sectionLabel(
            'User Credentials',
            'Users log in with these credentials to access the attendance kiosk.',
          ),
          const SizedBox(height: 14),
          ResponsiveGridRow(
            children: [
              // Username field
              ResponsiveGridCol(
                xl: 6,
                lg: 6,
                md: 6,
                xs: 12,
                sm: 12,
                child: Padding(
                  padding: EdgeInsets.only(top: 0, right: isWide ? 8.0 : 0.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SriTextField(
                        controller: kioskUsernameCtrl,
                        label: 'Username *',
                        readOnly: !editing,
                        prefixIcon: Icons.person_outline_rounded,
                        onChanged: onUsernameChanged,
                        // Preserve exact case — no transformation
                        suffixIconWidget: isCheckingUsername
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : usernameVerified &&
                                  kioskUsernameCtrl.text.isNotEmpty &&
                                  editing
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.accentGreen,
                                size: 18,
                              )
                            : null,
                        validator: (v) {
                          if (kioskEnabled && (v == null || v.trim().isEmpty)) {
                            return 'Username is required';
                          }
                          if (v != null && v.contains(' ')) {
                            return 'Username cannot contain spaces';
                          }
                          if (usernameError != null) return usernameError;
                          return null;
                        },
                      ),
                      if (usernameError != null && editing) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            usernameError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                      if (usernameVerified &&
                          !isCheckingUsername &&
                          kioskUsernameCtrl.text.isNotEmpty &&
                          editing) ...[
                        const SizedBox(height: 4),
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text(
                            'Username is available ✓',
                            style: TextStyle(
                              color: AppColors.accentGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Password field
              ResponsiveGridCol(
                xl: 6,
                lg: 6,
                md: 6,
                xs: 12,
                sm: 12,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: isWide ? 0.0 : 12,
                    left: isWide ? 8.0 : 0.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SriTextField(
                        controller: kioskPasswordCtrl,
                        label:
                            (widget.company.kioskUsername != null &&
                                !isUsernameChanged)
                            ? 'New Password (leave blank to keep)'
                            : 'Password *',
                        readOnly: !editing,
                        obscureText: !kioskPasswordVisible,
                        prefixIcon: Icons.lock_outline_rounded,
                        onChanged: onPasswordChanged,
                        suffixIcon: kioskPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        onSuffixTap: () => setState(
                          () => kioskPasswordVisible = !kioskPasswordVisible,
                        ),
                        validator: (v) {
                          final hasExisting =
                              widget.company.kioskUsername != null;

                          if (kioskEnabled &&
                              ((!hasExisting) || isUsernameChanged) &&
                              (v == null || v.isEmpty)) {
                            return isUsernameChanged
                                ? 'Password is required when changing username'
                                : 'Password is required';
                          }

                          if (v != null && v.isNotEmpty && v.length < 6) {
                            return 'Minimum 6 characters';
                          }

                          if (passwordError != null) {
                            return passwordError;
                          }

                          return null;
                        },
                      ),
                      if (passwordError != null) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            passwordError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ] else if (kioskPasswordCtrl.text.isNotEmpty &&
                          kioskPasswordCtrl.text.length >= 6) ...[
                        const SizedBox(height: 4),
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text(
                            'Password looks good ✓',
                            style: TextStyle(
                              color: AppColors.accentGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Helper: section label + subtitle ────────────────────
  Widget _sectionLabel(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ── Helper: styled radio option ──────────────────────────
  Widget _radioOption<T>({
    required String label,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<T>(
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Header card ─────────────────────────────────────────
  Widget headerCard() {
    final c = widget.company;
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B5BDB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: editing ? pickLogo : null,
            child: Stack(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: logoBytes != null
                      ? Image.memory(logoBytes!, fit: BoxFit.cover)
                      : (c.logoUrl?.isNotEmpty == true
                            ? Image.network(
                                c.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    widget.controller.logoPlaceholder(c),
                              )
                            : widget.controller.logoPlaceholder(c)),
                ),
                if (editing)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Nunito',
                  ),
                ),
                if (c.city?.isNotEmpty == true || c.state?.isNotEmpty == true)
                  Text(
                    '${c.city ?? ''}, ${c.state ?? ''}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                  ),
                if (c.phone?.isNotEmpty == true)
                  Text(
                    c.phone!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.canEdit)
            IconButton(
              onPressed: () => setState(() => editing = !editing),
              icon: Icon(
                editing ? Icons.close : Icons.edit_rounded,
                color: Colors.white,
              ),
              tooltip: editing ? 'Cancel Edit' : 'Edit',
            ),
        ],
      ),
    );
  }

  Future<void> pickLogo() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
    );
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() {
        logoBytes = bytes;
        logoPath = img.path;
      });
    }
  }
}