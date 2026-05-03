import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/department_model.dart';
import 'package:sri_hr/data/models/employee_model.dart';
import 'package:sri_hr/data/models/role_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/company/controller/company_controller.dart';
import 'package:sri_hr/presentation/department/controller/department_controller.dart';
import 'package:sri_hr/presentation/designation/controller/role_controller.dart';
import 'package:sri_hr/presentation/employee/controller/employee_controller.dart';
import 'package:sri_hr/presentation/employee_status/controller/employee_status_controller.dart';
import 'package:sri_hr/presentation/salary_type/controller/salary_type_controller.dart';
import 'package:sri_hr/widgets/sri_dropdown.dart';
import 'package:sri_hr/widgets/sri_textfield.dart';

class EmployeeFormPage extends StatefulWidget {
  final EmployeeModel? employee;
  final EmployeeController controller;
  const EmployeeFormPage({super.key, this.employee, required this.controller});

  @override
  State<EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage>
    with SingleTickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();
  late TabController tabCtrl;
  bool isLoading = false;
  bool get isEdit => widget.employee != null;

  // ── Controllers ──────────────────────────────
  late TextEditingController code,
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
  // Documents list: each item = {name, bytes, path}
  final List<Map<String, dynamic>> documents = [];

  // ── Controllers refs ──────────────────────────
  late final DepartmentController deptCtrl;
  late final RoleController roleCtrl;
  late final EmployeeStatusController statusCtrl;
  late final SalaryTypeController salaryCtrl;
  late final CompanyController companyCtrl;

  @override
  void initState() {
    super.initState();
    tabCtrl = TabController(length: 4, vsync: this);
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

    if (!isEdit) _generateCode();
  }

  @override
  void dispose() {
    tabCtrl.dispose();
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

  Future<void> _generateCode([String? forCompanyId]) async {
    // Generate code for the SELECTED branch, not always the active one
    final cid =
        forCompanyId ?? companyId ?? Get.find<AuthController>().companyId;
    final codee = await widget.controller.generateCode(cid);
    setState(() {
      code.text = codee;
      username.text = codee;
    });
  }

  // ── Auto-fill from designation ────────────────
  void _onDesignationChanged(String? roleId) {
    setState(() => roleId = roleId);
    if (roleId == null) return;
    final role = roleCtrl.roles.firstWhereOrNull((r) => r.id == roleId);
    if (role != null) {
      casualLeave.text = '${role.casualLeave}';
    }
  }

  // ── Auto-fill from department ─────────────────
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isEdit ? 'Edit Employee' : 'Add Employee',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      isEdit ? 'Update' : 'Save Employee',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
        ],
        bottom: TabBar(
          controller: tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.person_rounded, size: 18), text: 'Basic'),
            Tab(
              icon: Icon(Icons.location_on_rounded, size: 18),
              text: 'Address',
            ),
            Tab(icon: Icon(Icons.work_rounded, size: 18), text: 'Work'),
            Tab(
              icon: Icon(Icons.lock_rounded, size: 18),
              text: 'Login & Docs',
            ),
          ],
        ),
      ),
      body: Form(
        key: formKey,
        child: TabBarView(
          controller: tabCtrl,
          children: [_TabBasic(), _TabAddress(), _TabWork(), _TabLoginDocs()],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // TAB 1 – BASIC INFO
  // ══════════════════════════════════════════════
  Widget _TabBasic() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile picture
          _ProfilePicPicker(
            bytes: profileBytes,
            onPick: (b, p) => setState(() {
              profileBytes = b;
              profilePath = p;
            }),
          ),
          const SizedBox(height: 24),

          // Code + Name
          _Card(
            children: [
              _Label('Employee Information'),
              _Row2(
                _Field(
                  code,
                  'Employee Code *',
                  Icons.badge_rounded,
                  validator: _req,
                  onChanged: (v) => username.text = v,
                ),
                _Field(
                  name,
                  'Full Name *',
                  Icons.person_rounded,
                  validator: _req,
                ),
              ),
              _Gap(),
              _Row2(
                _DateField(
                  doj,
                  'Date of Joining',
                  Icons.calendar_today_rounded,
                ),
                _DateField(
                  dob,
                  'Date of Birth *',
                  Icons.cake_rounded,
                  validator: _req,
                ),
              ),
              _Gap(),
              _Row2(
                _GenderDrop(),
                _Field(
                  fatherName,
                  'Father / Husband Name',
                  Icons.people_rounded,
                ),
              ),
              _Gap(),
              _Field(
                mobile,
                'Mobile Number',
                Icons.phone_rounded,
                keyboard: TextInputType.phone,
              ),
              _Gap(),
              _Field(
                email,
                'Email Address',
                Icons.email_outlined,
                keyboard: TextInputType.emailAddress,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status + Salary
          _Card(
            children: [
              _Label('Status & Salary'),
              _Row2(_StatusDrop(), _SalaryDrop()),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // TAB 2 – ADDRESS
  // ══════════════════════════════════════════════
  Widget _TabAddress() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _Card(
            children: [
              _Label('Residential Address'),
              _Field(address, 'Full Address', Icons.home_rounded, maxLines: 3),
              _Gap(),
              _Row2(
                _Field(country, 'Country', Icons.flag_rounded),
                _Field(state, 'State', Icons.map_rounded),
              ),
              _Gap(),
              _Row2(
                _Field(city, 'City', Icons.location_city_rounded),
                _Field(
                  pincode,
                  'Pincode',
                  Icons.pin_drop_rounded,
                  keyboard: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Card(
            children: [
              _Label('Aadhar Address'),
              _Field(
                aadharAddress,
                'Aadhar Registered Address',
                Icons.credit_card_rounded,
                maxLines: 3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // TAB 3 – WORK
  // ══════════════════════════════════════════════
  Widget _TabWork() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _Card(
            children: [
              _Label('Department & Role'),
              // Company dropdown (from org's branches)
              Obx(() => _CompanyDrop()),
              _Gap(),
              _Row2(
                Obx(() {
                  final ids = deptCtrl.departments.map((d) => d.id).toList();
                  return SriDropdown<String>(
                    value: _safeVal(departmentId, ids),
                    label: 'Department *',
                    prefixIcon: Icons.account_tree_rounded,
                    items: deptCtrl.departments
                        .map(
                          (d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.name),
                          ),
                        )
                        .toList(),
                    onChanged: _onDepartmentChanged,
                    validator: (v) => v == null ? 'Required' : null,
                  );
                }),
                Obx(() {
                  final ids = roleCtrl.roles.map((r) => r.id).toList();
                  return SriDropdown<String>(
                    value: _safeVal(roleId, ids),
                    label: 'Designation *',
                    prefixIcon: Icons.badge_rounded,
                    items: roleCtrl.roles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r.id,
                            child: Text(r.name),
                          ),
                        )
                        .toList(),
                    onChanged: _onDesignationChanged,
                    validator: (v) => v == null ? 'Required' : null,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Card(
            children: [
              _Label('Work Settings'),
              _Row2(
                _Field(
                  casualLeave,
                  'Casual Leave (days/yr)',
                  Icons.event_busy_rounded,
                  keyboard: TextInputType.number,
                ),
                const SizedBox.shrink(),
              ),
              _Gap(),
              _SwitchTile(
                label: 'Mobile Login Allowed',
                subtitle: 'Employee can login via mobile app',
                icon: Icons.phone_android_rounded,
                value: mobileLogin,
                onChanged: (v) => setState(() => mobileLogin = v),
              ),
              const SizedBox(height: 8),
              _SwitchTile(
                label: 'Outside Office Allowed',
                subtitle: 'Employee can mark attendance outside office',
                icon: Icons.location_off_rounded,
                value: outsideOffice,
                onChanged: (v) => setState(() => outsideOffice = v),
              ),
              const SizedBox(height: 8),
              _SwitchTile(
                label: 'Active Employee',
                subtitle: 'Inactive employees cannot login',
                icon: Icons.toggle_on_rounded,
                value: isActive,
                onChanged: (v) => setState(() => isActive = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // TAB 4 – LOGIN & DOCUMENTS
  // ══════════════════════════════════════════════
  Widget _TabLoginDocs() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Login credentials
          _Card(
            children: [
              _Label('Login Credentials'),
              _Field(
                username,
                'Username',
                Icons.person_outline_rounded,
                hint: 'Default: Employee Code',
              ),
              if (!isEdit) ...[
                _Gap(),
                SriTextField(
                  controller: password,
                  label: 'Password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  hint: 'Leave blank for no login access',
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
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
                        'Employee can login using username or email.',
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
          // Documents
          _Card(
            children: [
              Row(
                children: [
                  _LabelWidget('Documents'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _pickDocument,
                    icon: const Icon(Icons.attach_file_rounded, size: 16),
                    label: const Text('Attach File'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (documents.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.folder_open_rounded,
                        size: 40,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No documents attached',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: documents.asMap().entries.map((entry) {
                    final i = entry.key;
                    final doc = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
                                  _formatBytes(
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
                            onTap: () => setState(() => documents.removeAt(i)),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // INLINE WIDGET HELPERS
  // ─────────────────────────────────────────────
  Widget _Card({required List<Widget> children}) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.all(18),
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
      children: children,
    ),
  );

  Widget _Label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
  );

  Widget _LabelWidget(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
  );

  Widget _Gap() => const SizedBox(height: 14);

  Widget _Row2(Widget a, Widget b) => Row(
    children: [
      Expanded(child: a),
      const SizedBox(width: 14),
      Expanded(child: b),
    ],
  );

  Widget _Field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? hint,
    TextInputType? keyboard,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) => SriTextField(
    controller: ctrl,
    label: label,
    hint: hint,
    prefixIcon: icon,
    keyboardType: keyboard,
    maxLines: maxLines,
    validator: validator,
    onChanged: onChanged,
  );

  Widget _DateField(
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
        context: context,
        initialDate: DateTime.now(),
        firstDate: firstDate ?? DateTime(1950),
        lastDate: lastDate ?? DateTime.now(),
      );
      if (d != null) ctrl.text = d.toIso8601String().substring(0, 10);
    },
  );

  // ── Safe value helper ───────────────────────────────────
  // Returns null if value not found in items list.
  // Prevents Flutter's DropdownButton assertion crash.
  String? _safeVal(String? value, List<String> ids) {
    if (value == null || ids.isEmpty) return null;
    return ids.contains(value) ? value : null;
  }

  Widget _GenderDrop() {
    const genders = ['male', 'female', 'other'];
    return SriDropdown<String>(
      value: _safeVal(gender, genders),
      label: 'Gender',
      prefixIcon: Icons.wc_rounded,
      items: genders
          .map(
            (g) => DropdownMenuItem(value: g, child: Text(g.capitalizeFirst!)),
          )
          .toList(),
      onChanged: (v) => setState(() => gender = v),
    );
  }

  Widget _StatusDrop() => Obx(() {
    final ids = statusCtrl.statuses.map((s) => s.id).toList();
    return SriDropdown<String>(
      value: _safeVal(statusId, ids),
      label: 'Employee Status',
      prefixIcon: Icons.toggle_on_rounded,
      items: statusCtrl.statuses
          .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
          .toList(),
      onChanged: (v) => setState(() => statusId = v),
    );
  });

  Widget _SalaryDrop() => Obx(() {
    final ids = salaryCtrl.salaryTypes.map((s) => s.id).toList();
    return SriDropdown<String>(
      value: _safeVal(salaryTypeId, ids),
      label: 'Salary Type',
      prefixIcon: Icons.payments_rounded,
      items: salaryCtrl.salaryTypes
          .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
          .toList(),
      onChanged: (v) => setState(() => salaryTypeId = v),
    );
  });

  Widget _CompanyDrop() {
    final companies = companyCtrl.companies;
    final ids = companies.map((c) => c.id).toList();
    return SriDropdown<String>(
      value: _safeVal(companyId, ids),
      label: 'Company / Branch *',
      prefixIcon: Icons.business_rounded,
      items: companies
          .map(
            (c) => DropdownMenuItem(
              value: c.id,
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        c.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (v) async {
        setState(() {
          companyId = v;
          // Reset dept/role since they belong to a different branch
          departmentId = null;
          roleId = null;
        });
        if (v == null) return;
        // ✅ Regenerate employee code for the newly selected branch
        if (!isEdit) _generateCode(v);
        // ✅ Load departments & designations for the selected branch
        await _loadBranchData(v);
      },
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Future<void> _loadBranchData(String companyId) async {
    try {
      // Load departments for selected branch
      final deptRows = await SupabaseService.client
          .from('departments')
          .select()
          .eq('company_id', companyId)
          .order('name');
      deptCtrl.departments.value = deptRows
          .map<DepartmentModel>((r) => DepartmentModel.fromJson(r))
          .toList();

      // Load roles/designations for selected branch
      final roleRows = await SupabaseService.client
          .from('roles')
          .select()
          .eq('company_id', companyId)
          .order('name');
      roleCtrl.roles.value = roleRows
          .map<RoleModel>((r) => RoleModel.fromJson(r))
          .toList();
    } catch (e) {
      debugPrint('[EmpForm] loadBranchData error: $e');
    }
  }

  Widget _SwitchTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool value,
    required void Function(bool) onChanged,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: value
          ? AppColors.primary.withOpacity(0.04)
          : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: value ? AppColors.primary.withOpacity(0.2) : AppColors.border,
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: value
                ? AppColors.primary.withOpacity(0.12)
                : AppColors.border.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: value ? AppColors.primary : AppColors.textMuted,
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
          activeColor: AppColors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    ),
  );

  // ─────────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────────
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

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String? _req(String? v) => v == null || v.trim().isEmpty ? 'Required' : null;

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) {
      // Jump to first tab with error
      tabCtrl.animateTo(0);
      return;
    }
    setState(() => isLoading = true);

    // Primary doc bytes (first document or null)
    Uint8List? aadharBytes;
    String? aadharPath;
    if (documents.isNotEmpty) {
      aadharBytes = documents.first['bytes'] as Uint8List;
      aadharPath = documents.first['path'] as String;
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
      if (!isEdit && password.text.isNotEmpty) 'password': password.text,
    };

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
}

// ─────────────────────────────────────────────
// PROFILE PICTURE PICKER
// ─────────────────────────────────────────────
class _ProfilePicPicker extends StatelessWidget {
  final Uint8List? bytes;
  final void Function(Uint8List, String) onPick;
  const _ProfilePicPicker({this.bytes, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final img = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 400,
        );
        if (img != null) {
          final b = await img.readAsBytes();
          onPick(b, img.path);
        }
      },
      child: Center(
        child: Stack(
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: bytes != null ? MemoryImage(bytes!) : null,
              child: bytes == null
                  ? const Icon(Icons.person, size: 48, color: AppColors.primary)
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
