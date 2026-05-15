import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/department_model.dart';
import 'package:sri_hr/data/models/employee_model.dart';
import 'package:sri_hr/data/models/role_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:sri_hr/data/utils/network_time.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/company/controller/company_controller.dart';
import 'package:sri_hr/presentation/department/controller/department_controller.dart';
import 'package:sri_hr/presentation/designation/controller/role_controller.dart';
import 'package:sri_hr/presentation/employee/controller/employee_controller.dart';
import 'package:sri_hr/presentation/employee_status/controller/employee_status_controller.dart';
import 'package:sri_hr/presentation/helper/helper.dart';
import 'package:sri_hr/presentation/salary_type/controller/salary_type_controller.dart';
import 'package:sri_hr/routes/app_routes.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/sri_dropdown.dart';
import 'package:sri_hr/widgets/sri_textfield.dart';

class EmployeeFormPage extends StatefulWidget {
  final EmployeeModel? employee;
  final EmployeeController controller;
  const EmployeeFormPage({super.key, this.employee, required this.controller});

  @override
  State<EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage> {
  // Stepper
  int currentStep = 0;
  bool emailChanged = false;
  final stepKeys = List.generate(4, (_) => GlobalKey<FormState>());
  bool isLoading = false;
  bool get isEdit => widget.employee != null;

  // ── Text Controllers ─────────────────────────
  late TextEditingController code,
      name,
      mobile,
      email,
      oldEmail,
      fatherName,
      address,
      aadharAddress,
      country,
      state,
      city,
      pincode,
      doj,
      dob,
      casualLeave,
      username,
      password;

  // ── Dropdown values ───────────────────────────
  String? departmentId, roleId, statusId, salaryTypeId, gender, companyId;

  // ── Switches ──────────────────────────────────
  bool mobileLogin = true;
  bool outsideOffice = false;
  bool isActive = true;

  // ── Files ─────────────────────────────────────
  Uint8List? profileBytes;
  String? profilePath;
  final List<Map<String, dynamic>> documents = [];

  // ── Controller refs ───────────────────────────
  late final DepartmentController deptCtrl;
  late final RoleController roleCtrl;
  late final EmployeeStatusController statusCtrl;
  late final SalaryTypeController salaryCtrl;
  late final CompanyController companyCtrl;

  static const stepTitles = [
    'Basic Info',
    'Address',
    'Work & Role',
    'Login & Docs',
  ];
  static const stepIcons = [
    Icons.person_rounded,
    Icons.location_on_rounded,
    Icons.work_rounded,
    Icons.lock_rounded,
  ];

  @override
  void initState() {
    super.initState();
    NetworkTime.syncTime();
    deptCtrl = Get.find<DepartmentController>();
    roleCtrl = Get.find<RoleController>();
    statusCtrl = Get.find<EmployeeStatusController>();
    salaryCtrl = Get.find<SalaryTypeController>();
    companyCtrl = Get.find<CompanyController>();

    final e = widget.employee;
    code = TextEditingController(text: e?.employeeCode ?? '');
    name = TextEditingController(text: e?.fullName ?? '');
    mobile = TextEditingController(text: e?.mobile ?? '');
    email = TextEditingController(text: e?.email ?? '');
    oldEmail = TextEditingController(text: e?.email ?? '');
    fatherName = TextEditingController(text: e?.fatherHusbandName ?? '');
    address = TextEditingController(text: e?.address ?? '');
    aadharAddress = TextEditingController(text: e?.aadharAddress ?? '');
    country = TextEditingController(text: e?.country ?? 'India');
    state = TextEditingController(text: e?.state ?? '');
    city = TextEditingController(text: e?.city ?? '');
    pincode = TextEditingController(text: e?.pincode ?? '');
    doj = TextEditingController(
      text: e?.doj?.toIso8601String().substring(0, 10) ?? '',
    );
    dob = TextEditingController(
      text: e?.dob?.toIso8601String().substring(0, 10) ?? '',
    );
    casualLeave = TextEditingController(text: '${e?.casualLeave ?? 12}');
    username = TextEditingController(text: e?.employeeCode ?? '');
    password = TextEditingController();

    departmentId = e?.departmentId;
    roleId = e?.roleId;
    statusId = e?.statusId;
    salaryTypeId = e?.salaryTypeId;
    gender = e?.gender?.name;
    companyId = e?.companyId ?? Get.find<AuthController>().companyId;
    mobileLogin = e?.mobileLogin ?? true;
    outsideOffice = e?.outsideOffice ?? false;
    isActive = e?.isActive ?? true;
    widget.controller.selectedProfile.value = null;

    if (!isEdit) _generateCode();
  }

  @override
  void dispose() {
    for (final c in [
      code,
      name,
      mobile,
      email,
      fatherName,
      address,
      aadharAddress,
      country,
      state,
      city,
      pincode,
      doj,
      dob,
      casualLeave,
      username,
      password,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ✅ Change this method to use previewCode
  Future<void> _generateCode([String? forCompanyId]) async {
    final cid =
        forCompanyId ?? companyId ?? Get.find<AuthController>().companyId;

    // Use preview — only shows next code, does NOT reserve it
    final codee = await widget.controller.previewCode(cid);

    setState(() {
      code.text = codee;
      username.text = codee;
    });
  }

  void _onDesignationChanged(String? selectedRoleId) {
    setState(() => roleId = selectedRoleId);
    if (selectedRoleId == null) return;
    final role = roleCtrl.roles.firstWhereOrNull((r) => r.id == selectedRoleId);
    if (role != null) casualLeave.text = '${role.casualLeave}';
  }

  void _onDepartmentChanged(String? deptId) {
    setState(() => departmentId = deptId);
    if (deptId == null) return;
    final dept = deptCtrl.departments.firstWhereOrNull((d) => d.id == deptId);
    if (dept != null) {
      setState(() {
        mobileLogin = dept.mobileLogin;
        outsideOffice = dept.outsideAttendance;
      });
    }
  }

  String? _safeVal(String? value, List<String> ids) {
    if (value == null || ids.isEmpty) return null;
    return ids.contains(value) ? value : null;
  }

  // ── Next / Back / Submit ─────────────────────
  void _next() {
    final controller = Get.isRegistered<EmployeeController>()
        ? Get.find<EmployeeController>()
        : Get.put(EmployeeController());
    final valid = stepKeys[currentStep].currentState?.validate() ?? true;
    final profileValid = kIsWeb
        ? (profileBytes != null ||
              (widget.employee?.profilePicture != null &&
                  widget.employee!.profilePicture!.isNotEmpty))
        : (controller.selectedProfile.value != null ||
              (widget.employee?.profilePicture != null &&
                  widget.employee!.profilePicture!.isNotEmpty));
    if (!profileValid) {
      showError(
        "Profile Image is Required. Upload Real Face Image for Face Attendance",
        title: "Required",
      );
    }
    if (!valid || !profileValid) return;
    if (currentStep < stepTitles.length - 1) {
      setState(() => currentStep++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submit() async {
    final controller = Get.find<EmployeeController>();
    setState(() => isLoading = true);
    String? profileUrl = widget.employee?.profilePicture;
    String? profileFaceTemplate = widget.employee?.profileTemplate;
    Uint8List? aadharBytes;
    String? aadharPath;
    if (documents.isNotEmpty) {
      aadharBytes = documents.first['bytes'] as Uint8List;
      aadharPath = documents.first['path'] as String;
    }

    if (!isEdit) {
      final reservedCode = await widget.controller.generateCode(companyId);
      code.text = reservedCode;
      username.text = reservedCode;
    }

    final data = {
      'company_id': companyId,
      'employee_code': code.text.trim(),
      'full_name': name.text.trim(),
      'department_id': departmentId,
      'role_id': roleId,
      'status_id': statusId,
      'salary_type_id': salaryTypeId,
      'mobile': mobile.text.trim(),
      'email': email.text.trim(),
      'gender': gender,
      'doj': doj.text.isNotEmpty ? doj.text : null,
      'dob': dob.text.isNotEmpty ? dob.text : null,
      'father_husband_name': fatherName.text.trim(),
      'address': address.text.trim(),
      'aadhar_address': aadharAddress.text.trim(),
      'country': country.text.trim(),
      'state': state.text.trim(),
      'city': city.text.trim(),
      'pincode': pincode.text.trim(),
      'casual_leave': int.tryParse(casualLeave.text) ?? 12,
      'mobile_login': mobileLogin,
      'outside_office': outsideOffice,
      'is_active': isActive,
      'username': username.text.trim(),
      if (password.text.isNotEmpty) 'password': password.text.trim(),
    };

    if (controller.faceTemplate != null) {
      Uint8List template = controller.faceTemplate;
      String base64Template = base64Encode(template);

      data['face_template'] = widget.employee != null
          ? controller.selectedProfile.value != null
                ? base64Template
                : widget.employee?.profileTemplate
          : base64Template;
    }

    if (isEdit) {
      await widget.controller.updateEmployee(
        widget.employee!.id,
        data,
        profileBytes: profileBytes,
        profilePath: profilePath,
      );
    } else {
      await widget.controller.createEmployee(
        data,
        profileBytes: profileBytes,
        profilePath: profilePath,
        aadharBytes: aadharBytes,
        aadharPath: aadharPath,
      );
    }
    setState(() => isLoading = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return isWide
        ? AppShell(
            currentModule: 'employee',
            title: 'Employee',
            child: formWidget(widget.employee),
          )
        : formWidget(widget.employee);
  }

  Widget formWidget(EmployeeModel? employee) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEdit ? 'Edit Employee' : 'Add Employee',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Step indicator header ────────────────
          _StepHeader(
            currentStep: currentStep,
            titles: stepTitles,
            icons: stepIcons,
            onStepTapped: (i) {
              // Only allow going back to completed steps
              if (i < currentStep) setState(() => currentStep = i);
            },
          ),
          // ── Step content ─────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(currentStep),
                child: Form(
                  key: stepKeys[currentStep],
                  child: _buildStep(currentStep, employee),
                ),
              ),
            ),
          ),
          // ── Bottom navigation ─────────────────────
          _StepFooter(
            currentStep: currentStep,
            totalSteps: stepTitles.length,
            isLoading: isLoading,
            isEdit: isEdit,
            onBack: _back,
            onNext: _next,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int step, EmployeeModel? employe) {
    return switch (step) {
      0 => _StepBasic(state: this, employee: employe),
      1 => _StepAddress(state: this),
      2 => _StepWork(state: this),
      3 => _StepLoginDocs(state: this),
      _ => const SizedBox(),
    };
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      withData: true,
    );
    if (result == null) return;
    setState(() {
      for (final f in result.files) {
        if (f.bytes != null) {
          documents.add({
            'name': f.name,
            'bytes': f.bytes!,
            'path': f.path ?? f.name,
          });
        }
      }
    });
  }

  Future<void> _loadBranchData(String companyId) async {
    try {
      final deptRows = await SupabaseService.client
          .from('departments')
          .select()
          .eq('company_id', companyId)
          .order('name');
      deptCtrl.departments.value = deptRows
          .map<DepartmentModel>((r) => DepartmentModel.fromJson(r))
          .toList();
      final roleRows = await SupabaseService.client
          .from('roles')
          .select()
          .eq('company_id', companyId)
          .order('name');
      roleCtrl.roles.value = roleRows
          .map<RoleModel>((r) => RoleModel.fromJson(r))
          .toList();
    } catch (e) {
      debugPrint('[EmpForm] loadBranchData: $e');
    }
  }

  String _formatBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ─────────────────────────────────────────────
// STEP HEADER INDICATOR
// ─────────────────────────────────────────────
class _StepHeader extends StatelessWidget {
  final int currentStep;
  final List<String> titles;
  final List<IconData> icons;
  final void Function(int) onStepTapped;
  const _StepHeader({
    required this.currentStep,
    required this.titles,
    required this.icons,
    required this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Row(
        children: List.generate(titles.length, (i) {
          final isDone = i < currentStep;
          final isCurrent = i == currentStep;
          return Expanded(
            child: GestureDetector(
              onTap: () => onStepTapped(i),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        // Circle
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? AppColors.accentGreen
                                : isCurrent
                                ? Colors.white
                                : Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: isCurrent
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : Icon(
                                    icons[i],
                                    color: isCurrent
                                        ? AppColors.primary
                                        : Colors.white,
                                    size: 18,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Label
                        Text(
                          titles[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isCurrent || isDone
                                ? Colors.white
                                : Colors.white.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Connector line
                  if (i < titles.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 22),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          gradient: LinearGradient(
                            colors: [
                              isDone
                                  ? AppColors.accentGreen
                                  : Colors.white.withOpacity(0.3),
                              i + 1 <= currentStep
                                  ? AppColors.accentGreen
                                  : Colors.white.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STEP FOOTER BUTTONS
// ─────────────────────────────────────────────
class _StepFooter extends StatelessWidget {
  final int currentStep, totalSteps;
  final bool isLoading, isEdit;
  final VoidCallback onBack, onNext;
  const _StepFooter({
    required this.currentStep,
    required this.totalSteps,
    required this.isLoading,
    required this.isEdit,
    required this.onBack,
    required this.onNext,
  });

  bool get isLast => currentStep == totalSteps - 1;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Back
          OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: Padding(
              padding: EdgeInsets.symmetric(vertical: isWide ? 4.0 : 0.0),
              child: Text(currentStep == 0 ? 'Cancel' : 'Back'),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Step dots
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                totalSteps,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == currentStep ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: i <= currentStep
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Next / Save
          ElevatedButton.icon(
            onPressed: isLoading ? null : onNext,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                    size: 16,
                  ),
            label: Padding(
              padding: EdgeInsets.symmetric(vertical: isWide ? 4.0 : 0.0),
              child: Text(
                isLoading
                    ? 'Saving...'
                    : isLast
                    ? (isEdit ? 'Update' : 'Save')
                    : 'Next',
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: isLast
                  ? AppColors.accentGreen
                  : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STEP 1 — BASIC INFO
// ─────────────────────────────────────────────
class _StepBasic extends StatefulWidget {
  final _EmployeeFormPageState state;
  final EmployeeModel? employee;
  const _StepBasic({required this.state, required this.employee});

  @override
  State<_StepBasic> createState() => _StepBasicState();
}

class _StepBasicState extends State<_StepBasic> {
  bool isChecking = false;
  String? emailError;
  Timer? debounce;

  bool isValidEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void onEmailChanged(String value) {
    // Cancel previous debounce
    debounce?.cancel();

    if (value.isEmpty) {
      setState(() => emailError = null);
      return;
    }

    if (!isValidEmail(value)) {
      setState(() => emailError = 'Enter a valid email address');
      return;
    }

    // Debounce API call by 600ms so it doesn't fire on every keystroke
    debounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() {
        isChecking = true;
        emailError = null;
      });

      final exists = await widget.state.widget.controller.isEmailExists(
        value,
        excludeEmployeeId: widget.state.widget.employee?.id,
      );

      if (mounted) {
        setState(() {
          isChecking = false;
          if (widget.state.oldEmail.text.toString() != value) {
            widget.state.emailChanged = true;
          } else {
            widget.state.emailChanged = false;
          }
          emailError = exists ? 'This email is already registered' : null;
        });
      }
    });
  }

  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isWide ? 20.0 : 10.0,
        24,
        isWide ? 20.0 : 10.0,
        8,
      ),
      child: Column(
        children: [
          // Profile pic
          _ProfilePicPicker(
            bytes: widget.state.profileBytes,
            employee: widget.employee,
            onPick: (b, p) => widget.state.setState(() {
              widget.state.profileBytes = b;
              widget.state.profilePath = p;
            }),
          ),
          const SizedBox(height: 28),
          _SectionCard(
            title: 'Employee Information',
            icon: Icons.badge_rounded,
            children: [
              ResponsiveGridRow(
                children: [
                  ResponsiveGridCol(
                    xl: 6,
                    lg: 6,
                    md: 6,
                    sm: 12,
                    xs: 12,
                    child: Padding(
                      padding: EdgeInsets.only(right: isWide ? 5.0 : 0.0),
                      child: _SriField(
                        widget.state.code,
                        'Employee Code *',
                        Icons.tag_rounded,
                        validator: _req,
                        onChanged: (v) => widget.state.username.text = v,
                      ),
                    ),
                  ),
                  ResponsiveGridCol(
                    xl: 6,
                    lg: 6,
                    md: 6,
                    sm: 12,
                    xs: 12,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: isWide ? 5.0 : 0.0,
                        top: isWide ? 0.0 : 16.0,
                      ),
                      child: _SriField(
                        widget.state.name,
                        'Full Name *',
                        Icons.person_rounded,
                        validator: _req,
                      ),
                    ),
                  ),
                  ResponsiveGridCol(
                    xl: 6,
                    lg: 6,
                    md: 6,
                    sm: 12,
                    xs: 12,
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: isWide ? 5.0 : 0.0,
                        top: 16.0,
                      ),
                      child: _DateField(
                        context,
                        widget.state.doj,
                        'Date of Joining',
                        Icons.calendar_today_rounded,
                        lastDate: NetworkTime.now().add(
                          const Duration(days: 365),
                        ),
                      ),
                    ),
                  ),
                  ResponsiveGridCol(
                    xl: 6,
                    lg: 6,
                    md: 6,
                    sm: 12,
                    xs: 12,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: isWide ? 5.0 : 0.0,
                        top: 16.0,
                      ),
                      child: _DateField(
                        context,
                        widget.state.dob,
                        'Date of Birth *',
                        Icons.cake_rounded,
                        validator: _req,
                        lastDate: NetworkTime.now(),
                      ),
                    ),
                  ),
                  ResponsiveGridCol(
                    xl: 6,
                    lg: 6,
                    md: 6,
                    sm: 12,
                    xs: 12,
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: isWide ? 5.0 : 0.0,
                        top: 16.0,
                      ),
                      child: _GenderDropdown(
                        value: widget.state.gender,
                        onChanged: (v) => widget.state.setState(
                          () => widget.state.gender = v,
                        ),
                      ),
                    ),
                  ),
                  ResponsiveGridCol(
                    xl: 6,
                    lg: 6,
                    md: 6,
                    sm: 12,
                    xs: 12,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: isWide ? 5.0 : 0.0,
                        top: 16.0,
                      ),
                      child: _SriField(
                        widget.state.fatherName,
                        'Father / Husband Name',
                        Icons.people_rounded,
                      ),
                    ),
                  ),
                  ResponsiveGridCol(
                    xl: 6,
                    lg: 6,
                    md: 6,
                    sm: 12,
                    xs: 12,
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: isWide ? 5.0 : 0.0,
                        top: 16.0,
                      ),
                      child: _SriField(
                        widget.state.mobile,
                        'Mobile Number *',
                        Icons.phone_rounded,
                        keyboard: TextInputType.phone,
                        validator: (v) {
                          if (v?.isEmpty == true) {
                            return 'Mobile Number is Required';
                          }
                          if (v!.length != 10) return 'Enter 10 digits';
                          return null;
                        },
                      ),
                    ),
                  ),
                  ResponsiveGridCol(
                    xl: 6,
                    lg: 6,
                    md: 6,
                    sm: 12,
                    xs: 12,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: isWide ? 5.0 : 0.0,
                        top: 16.0,
                      ),
                      child: _SriField(
                        widget.state.email,
                        'Email Address *',
                        Icons.email_outlined,
                        keyboard: TextInputType.emailAddress,
                        onChanged: onEmailChanged,
                        errorText: emailError,
                        suffixIconWidget: isChecking
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
                            : emailError == null &&
                                  widget.state.email.text.isNotEmpty
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.accentGreen,
                                size: 18,
                              )
                            : null,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Email is required';
                          } else if (!isValidEmail(v)) {
                            return 'Enter Valid Email';
                          } else if (emailError != null) {
                            return emailError;
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Status & Salary',
            icon: Icons.payments_rounded,
            children: [
              ResponsiveGridRow(
                children: [
                  ResponsiveGridCol(
                    xl: 6,
                    lg: 6,
                    md: 6,
                    sm: 12,
                    xs: 12,
                    child: Obx(() {
                      final ids = widget.state.statusCtrl.statuses
                          .map((s) => s.id)
                          .toList();
                      return Padding(
                        padding: EdgeInsets.only(right: isWide ? 5.0 : 0.0),
                        child: SriDropdown<String>(
                          value: widget.state._safeVal(
                            widget.state.statusId,
                            ids,
                          ),
                          label: 'Employee Status',
                          prefixIcon: Icons.toggle_on_rounded,
                          items: widget.state.statusCtrl.statuses
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => widget.state.setState(
                            () => widget.state.statusId = v,
                          ),
                        ),
                      );
                    }),
                  ),
                  ResponsiveGridCol(
                    xl: 6,
                    lg: 6,
                    md: 6,
                    sm: 12,
                    xs: 12,
                    child: Obx(() {
                      final ids = widget.state.salaryCtrl.salaryTypes
                          .map((s) => s.id)
                          .toList();
                      return Padding(
                        padding: EdgeInsets.only(
                          left: isWide ? 5.0 : 0.0,
                          top: isWide ? 0.0 : 16.0,
                        ),
                        child: SriDropdown<String>(
                          value: widget.state._safeVal(
                            widget.state.salaryTypeId,
                            ids,
                          ),
                          label: 'Salary Type',
                          prefixIcon: Icons.payments_rounded,
                          items: widget.state.salaryCtrl.salaryTypes
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => widget.state.setState(
                            () => widget.state.salaryTypeId = v,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STEP 2 — ADDRESS
// ─────────────────────────────────────────────
class _StepAddress extends StatelessWidget {
  final _EmployeeFormPageState state;
  const _StepAddress({required this.state});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        children: [
          _SectionCard(
            title: 'Residential Address',
            icon: Icons.home_rounded,
            children: [
              ResponsiveGridRow(
                children: [
                  ResponsiveGridCol(
                    xl: 12,
                    lg: 12,
                    md: 12,
                    sm: 12,
                    xs: 12,
                    child: _SriField(
                      state.address,
                      'Full Address',
                      Icons.home_outlined,
                      maxLines: 3,
                    ),
                  ),
                  ResponsiveGridCol(
                    xl: 6,
                    lg: 6,
                    md: 6,
                    sm: 6,
                    xs: 6,
                    child: Padding(
                      padding: EdgeInsets.only(right: 5.0, top: 16.0),
                      child: _SriField(
                        state.country,
                        'Country',
                        Icons.flag_rounded,
                      ),
                    ),
                  ),
                  ResponsiveGridCol(
                    xl: 6,
                    lg: 6,
                    md: 6,
                    sm: 6,
                    xs: 6,
                    child: Padding(
                      padding: EdgeInsets.only(left: 5.0, top: 16.0),
                      child: _SriField(state.state, 'State', Icons.map_rounded),
                    ),
                  ),
                  ResponsiveGridCol(
                    xl: 6,
                    lg: 6,
                    md: 6,
                    sm: 6,
                    xs: 6,
                    child: Padding(
                      padding: EdgeInsets.only(right: 5.0, top: 16.0),
                      child: _SriField(
                        state.city,
                        'City',
                        Icons.location_city_rounded,
                      ),
                    ),
                  ),
                  ResponsiveGridCol(
                    xl: 6,
                    lg: 6,
                    md: 6,
                    sm: 6,
                    xs: 6,
                    child: Padding(
                      padding: EdgeInsets.only(left: 5.0, top: 16.0),
                      child: _SriField(
                        state.pincode,
                        'Pincode',
                        Icons.pin_drop_rounded,
                        keyboard: TextInputType.number,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Aadhar Address',
            icon: Icons.credit_card_rounded,
            children: [
              ResponsiveGridRow(
                children: [
                  ResponsiveGridCol(
                    xl: 12,
                    lg: 12,
                    md: 12,
                    sm: 12,
                    xs: 12,
                    child: _SriField(
                      state.aadharAddress,
                      'Aadhar Registered Address',
                      Icons.credit_card_outlined,
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STEP 3 — WORK & ROLE
// ─────────────────────────────────────────────
class _StepWork extends StatelessWidget {
  final _EmployeeFormPageState state;
  const _StepWork({required this.state});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        children: [
          _SectionCard(
            title: 'Company & Department',
            icon: Icons.business_rounded,
            children: [
              ResponsiveGridRow(
                children: [
                  // Company dropdown
                  ResponsiveGridCol(
                    xl: 12,
                    lg: 12,
                    md: 12,
                    sm: 12,
                    xs: 12,
                    child: Obx(() {
                      final companies = state.companyCtrl.companies;
                      final ids = companies.map((c) => c.id).toList();
                      return SriDropdown<String>(
                        value: state._safeVal(state.companyId, ids),
                        label: 'Company / Branch *',
                        prefixIcon: Icons.business_rounded,
                        items: companies
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Center(
                                        child: Text(
                                          c.name.substring(0, 1).toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        c.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) async {
                          state.setState(() {
                            state.companyId = v;
                            state.departmentId = null;
                            state.roleId = null;
                          });
                          if (v == null) return;
                          if (!state.isEdit) state._generateCode(v);
                          await state._loadBranchData(v);
                        },
                        validator: (v) => v == null ? 'Required' : null,
                      );
                    }),
                  ),
                  ResponsiveGridCol(
                    xl: 6,
                    lg: 6,
                    md: 6,
                    sm: 12,
                    xs: 12,
                    child: Obx(() {
                      final ids = state.deptCtrl.departments
                          .map((d) => d.id)
                          .toList();
                      return Padding(
                        padding: EdgeInsets.only(
                          right: isWide ? 5.0 : 0.0,
                          top: 16.0,
                        ),
                        child: SriDropdown<String>(
                          value: state._safeVal(state.departmentId, ids),
                          label: 'Department *',
                          prefixIcon: Icons.account_tree_rounded,
                          items: state.deptCtrl.departments
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d.id,
                                  child: Text(d.name),
                                ),
                              )
                              .toList(),
                          onChanged: state._onDepartmentChanged,
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      );
                    }),
                  ),
                  ResponsiveGridCol(
                    xl: 6,
                    lg: 6,
                    md: 6,
                    sm: 12,
                    xs: 12,
                    child: Obx(() {
                      final ids = state.roleCtrl.roles
                          .map((r) => r.id)
                          .toList();
                      return Padding(
                        padding: EdgeInsets.only(
                          left: isWide ? 5.0 : 0.0,
                          top: 16.0,
                        ),
                        child: SriDropdown<String>(
                          value: state._safeVal(state.roleId, ids),
                          label: 'Designation *',
                          prefixIcon: Icons.badge_rounded,
                          items: state.roleCtrl.roles
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r.id,
                                  child: Text(r.name),
                                ),
                              )
                              .toList(),
                          onChanged: state._onDesignationChanged,
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Work Settings',
            icon: Icons.tune_rounded,
            children: [
              ResponsiveGridRow(
                children: [
                  ResponsiveGridCol(
                    xl: 12,
                    lg: 12,
                    md: 12,
                    sm: 12,
                    xs: 12,
                    child: _SriField(
                      state.casualLeave,
                      'Casual Leave (days/year)',
                      Icons.event_busy_rounded,
                      keyboard: TextInputType.number,
                    ),
                  ),
                  ResponsiveGridCol(
                    xl: 12,
                    lg: 12,
                    md: 12,
                    sm: 12,
                    xs: 12,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: _ToggleCard(
                        icon: Icons.phone_android_rounded,
                        label: 'Mobile Login Allowed',
                        subtitle: 'Can login via mobile app',
                        value: state.mobileLogin,
                        onChanged: (v) =>
                            state.setState(() => state.mobileLogin = v),
                      ),
                    ),
                  ),
                  ResponsiveGridCol(
                    xl: 12,
                    lg: 12,
                    md: 12,
                    sm: 12,
                    xs: 12,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: _ToggleCard(
                        icon: Icons.location_off_rounded,
                        label: 'Outside Office Allowed',
                        subtitle: 'Can mark attendance outside office',
                        value: state.outsideOffice,
                        onChanged: (v) =>
                            state.setState(() => state.outsideOffice = v),
                      ),
                    ),
                  ),
                  ResponsiveGridCol(
                    xl: 12,
                    lg: 12,
                    md: 12,
                    sm: 12,
                    xs: 12,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: _ToggleCard(
                        icon: Icons.check_circle_rounded,
                        label: 'Active Employee',
                        subtitle: 'Inactive employees cannot login',
                        value: state.isActive,
                        color: AppColors.accentGreen,
                        onChanged: (v) =>
                            state.setState(() => state.isActive = v),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STEP 4 — LOGIN & DOCUMENTS
// ─────────────────────────────────────────────
class _StepLoginDocs extends StatelessWidget {
  final _EmployeeFormPageState state;
  const _StepLoginDocs({required this.state});

  @override
  Widget build(BuildContext context) {
    String? validatePassword(String? value) {
      if (value == null || value.isEmpty) {
        return 'Password cannot be empty';
      }
      if (value.length < 8) {
        return 'Must be at least 8 characters';
      }
      if (!value.contains(RegExp(r'[A-Z]'))) {
        return 'Must contain at least one uppercase letter';
      }
      if (!value.contains(RegExp(r'[a-z]'))) {
        return 'Must contain at least one lowercase letter';
      }
      if (!value.contains(RegExp(r'[0-9]'))) {
        return 'Must contain at least one number';
      }
      if (!value.contains(RegExp(r'[^A-Za-z0-9\s]'))) {
        return 'Must contain at least one special character';
      }
      if (value.contains(RegExp(r'\s'))) {
        return 'Password must not contain spaces';
      }
      return null; // all good
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        children: [
          _SectionCard(
            title: 'Login Credentials',
            icon: Icons.lock_rounded,
            children: [
              ResponsiveGridRow(
                children: [
                  ResponsiveGridCol(
                    xl: 12,
                    lg: 12,
                    md: 12,
                    sm: 12,
                    xs: 12,
                    child: _SriField(
                      state.username,
                      'Username',
                      Icons.person_outline_rounded,
                      hint: 'Default: Employee Code',
                    ),
                  ),
                  // if (!state.isEdit)
                  ResponsiveGridCol(
                    xl: 12,
                    lg: 12,
                    md: 12,
                    sm: 12,
                    xs: 12,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: SriTextField(
                        controller: state.password,
                        label: !state.isEdit ? 'Password *' : 'Password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                        hint: 'Leave blank for no login access',
                        validator: !state.isEdit || state.emailChanged
                            ? validatePassword
                            : null,
                      ),
                    ),
                  ),
                ],
              ),

              if (!state.isEdit) ...[_Gap()],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.info.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.info,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Username defaults to Employee Code. '
                        'Employee can login with username or email.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Documents',
            icon: Icons.attach_file_rounded,
            trailing: TextButton.icon(
              onPressed: state._pickDocument,
              icon: const Icon(Icons.upload_file_rounded, size: 16),
              label: const Text('Attach File'),
            ),
            children: [
              if (state.documents.isEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.folder_open_rounded,
                            size: 28,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'No documents attached',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'PDF, JPG, PNG, DOC supported',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: state.documents.asMap().entries.map((entry) {
                    final i = entry.key;
                    final doc = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.insert_drive_file_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  state._formatBytes(
                                    (doc['bytes'] as Uint8List).length,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => state.setState(
                              () => state.documents.removeAt(i),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHARED STEP WIDGETS
// ─────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.04),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: const Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (trailing != null) ...[const Spacer(), trailing!],
              ],
            ),
          ),
          // Card body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool value;
  final void Function(bool) onChanged;
  final Color color;
  const _ToggleCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.05) : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? color.withOpacity(0.25) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: value
                  ? color.withOpacity(0.12)
                  : AppColors.border.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: value ? color : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

Widget _SriField(
  TextEditingController ctrl,
  String label,
  IconData icon, {
  String? hint,
  String? errorText,
  TextInputType? keyboard,
  int maxLines = 1,
  Widget? suffixIconWidget,
  String? Function(String?)? validator,
  void Function(String)? onChanged,
}) => SriTextField(
  controller: ctrl,
  label: label,
  hint: hint,
  prefixIcon: icon,
  errorText: errorText,
  suffixIconWidget: suffixIconWidget,
  keyboardType: keyboard,
  maxLines: maxLines,
  validator: validator,
  onChanged: onChanged,
);

Widget _DateField(
  BuildContext ctx,
  TextEditingController ctrl,
  String label,
  IconData icon, {
  String? Function(String?)? validator,
  DateTime? firstDate,
  DateTime? lastDate,
}) => SriTextField(
  controller: ctrl,
  label: label,
  prefixIcon: icon,
  readOnly: true,
  validator: validator,
  onTap: () async {
    final d = await showDatePicker(
      context: ctx,
      initialDate: DateTime.tryParse(ctrl.text) ?? NetworkTime.now(),
      firstDate: firstDate ?? DateTime(1950),
      lastDate: lastDate ?? DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (d != null) ctrl.text = d.toIso8601String().substring(0, 10);
  },
);

Widget _GenderDropdown({
  String? value,
  required void Function(String?) onChanged,
}) {
  const genders = ['male', 'female', 'other'];
  return SriDropdown<String>(
    value: genders.contains(value) ? value : null,
    label: 'Gender',
    prefixIcon: Icons.wc_rounded,
    items: genders
        .map((g) => DropdownMenuItem(value: g, child: Text(g.capitalizeFirst!)))
        .toList(),
    onChanged: onChanged,
  );
}

Widget _Gap() => const SizedBox(height: 14);

String? _req(String? v) => v == null || v.trim().isEmpty ? 'Required' : null;

// ─────────────────────────────────────────────
// PROFILE PIC PICKER
// ─────────────────────────────────────────────
class _ProfilePicPicker extends StatefulWidget {
  final Uint8List? bytes;
  final EmployeeModel? employee;
  final void Function(Uint8List, String) onPick;
  const _ProfilePicPicker({
    this.bytes,
    required this.onPick,
    required this.employee,
  });

  @override
  State<_ProfilePicPicker> createState() => _ProfilePicPickerState();
}

class _ProfilePicPickerState extends State<_ProfilePicPicker> {
  final controller = Get.isRegistered<EmployeeController>()
      ? Get.find<EmployeeController>()
      : Get.put(EmployeeController());
  @override
  Widget build(BuildContext context) {
    return kIsWeb
        ? Center(
            child: GestureDetector(
              onTap: () async {
                final img = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 400,
                );
                if (img != null) {
                  final b = await img.readAsBytes();
                  widget.onPick(b, img.path);
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    backgroundImage: widget.bytes != null
                        ? MemoryImage(widget.bytes!)
                        : (widget.employee?.profilePicture != null &&
                              widget.employee!.profilePicture!.isNotEmpty)
                        ? NetworkImage(widget.employee!.profilePicture!)
                        : null,
                    child:
                        widget.bytes == null &&
                            (widget.employee?.profilePicture == null ||
                                widget.employee!.profilePicture!.isEmpty)
                        ? const Icon(
                            Icons.person,
                            size: 52,
                            color: Colors.white70,
                          )
                        : SizedBox(),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 17,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : Obx(
            () => Center(
              child: GestureDetector(
                onTap: captureFace,
                child: Container(
                  width: 90.0,
                  height: 90.0,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                    image: controller.selectedProfile.value != null
                        ? DecorationImage(
                            image: FileImage(controller.selectedProfile.value!),
                            fit: BoxFit.cover,
                          )
                        : (widget.employee?.profilePicture != null &&
                              widget.employee!.profilePicture!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(
                              widget.employee!.profilePicture!,
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: controller.selectedProfile.value != null
                      ? SizedBox()
                      : widget.employee?.profilePicture != null
                      ? SizedBox()
                      : const Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                          size: 40,
                        ),
                ),
              ),
            ),
          );
    /*Center(
      child: GestureDetector(
        onTap: () async {
          captureFace();
          // final img = await ImagePicker().pickImage(
          //   source: ImageSource.gallery,
          //   maxWidth: 400,
          // );
          // if (img != null) {
          //   final b = await img.readAsBytes();
          //   widget.onPick(b, img.path);
          // }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              backgroundImage: widget.bytes != null
                  ? MemoryImage(widget.bytes!)
                  : null,
              child: widget.bytes == null
                  ? const Icon(Icons.person, size: 52, color: Colors.white70)
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 17,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );*/
  }

  Future<void> captureFace() async {
    controller.faceTemplate = "";
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context, ImageSource.camera);
                controller.faceTemplate = "";

                final capturedImage = await Get.toNamed(
                  AppRoutes.routeFaceCapture,
                );

                File imageFile = await controller.uint8ListToFile(
                  capturedImage["face_URL"],
                  'image${DateTime.now()}.png',
                );

                setState(() {
                  controller.faceImage = imageFile;
                  controller.selectedProfile.value = imageFile;
                  controller.faceTemplate = capturedImage["face_template"];
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == ImageSource.gallery) {
      if (source != null) {
        final xFile = await ImagePicker().pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 512,
        );
        if (xFile == null) return;
        var rotatedImage = await FlutterExifRotation.rotateImage(
          path: xFile.path,
        );
        final faces = await controller.facesdkPlugin.extractFaces(
          rotatedImage.path,
        );
        if (faces.length == 0) {
          Get.snackbar(
            "Warning",
            "No Face Detected!",
            margin: EdgeInsets.all(10.0),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.warning.withOpacity(0.2),
            leftBarIndicatorColor: AppColors.warning,
          );
          return;
        }
        if (faces.length > 1) {
          Get.snackbar(
            "Warning",
            "MultiFace Detected!",
            margin: EdgeInsets.all(10.0),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.warning.withOpacity(0.2),
            leftBarIndicatorColor: AppColors.warning,
          );
          return;
        }
        for (int i = 0; i < faces.length; i++) {
          if (i == 0) {
            File imageFile = await controller.uint8ListToFile(
              faces[i]["faceJpg"],
              "image${DateTime.now()}.png",
            );
            setState(() {
              controller.faceImage = imageFile;
              controller.selectedProfile.value = imageFile;
              controller.faceTemplate = faces[i]["templates"];
            });
          }
        }
      }
    }
  }
}
