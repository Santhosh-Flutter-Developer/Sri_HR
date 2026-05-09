import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:facesdk_plugin/facesdk_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sri_hr/core/constants/app_constants.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/employee_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/employee/repository/employee_repository.dart';
import 'package:sri_hr/presentation/employee/ui/employee_form_page.dart';
import 'package:sri_hr/presentation/helper/helper.dart';

AuthController get auth => Get.find<AuthController>();

class EmployeeController extends GetxController {
  final _repo = EmployeeRepository();
  final employees = <EmployeeModel>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  dynamic faceTemplate;
  File? faceImage;
  final selectedProfile = Rx<File?>(null);

  final facesdkPlugin = FacesdkPlugin();
  final RxString warningStates = "".obs;
  final RxBool visibleWarnings = false.obs;

  // Only these keys exist as columns in the employees table.
  // Any extra key (password, username, departments, roles…) is stripped before insert.
  static const _employeeCols = {
    'company_id',
    'user_id',
    'department_id',
    'role_id',
    'status_id',
    'salary_type_id',
    'employee_code',
    'full_name',
    'doj',
    'dob',
    'gender',
    'mobile',
    'father_husband_name',
    'address',
    'aadhar_address',
    'country',
    'state',
    'city',
    'pincode',
    'email',
    'profile_picture',
    'aadhar_doc_url',
    'other_doc_url',
    'casual_leave',
    'mobile_login',
    'outside_office',
    'face_template',
    'is_active',
  };

  @override
  void onInit() {
    super.onInit();
    if (!kIsWeb) {
      faceInit();
    }
    loadEmployees();
  }

  Future<File> uint8ListToFile(Uint8List bytes, String fileName) async {
    final directory =
        await getTemporaryDirectory(); // or getApplicationDocumentsDirectory()
    final filePath = '${directory.path}/$fileName';

    File file = File(filePath);
    await file.writeAsBytes(bytes);

    return file;
  }

  Future<void> faceInit() async {
    RxInt facepluginState = (-1).obs;
    RxString warningState = "".obs;
    RxBool visibleWarning = false.obs;

    try {
      if (Platform.isAndroid) {
        await facesdkPlugin
            .setActivation(AppConstants.androidfacesdkLicence)
            .then((value) {
              return facepluginState.value = value ?? -1;
            });
      } else {
        await facesdkPlugin.setActivation(AppConstants.iosfacesdkLicence).then((
          value,
        ) {
          return facepluginState.value = value ?? -1;
        });
      }

      if (facepluginState.value == 0) {
        await facesdkPlugin.init().then(
          (value) => facepluginState.value = value ?? -1,
        );
      }
    } catch (e) {
      log("Face Init Error: $e");
    }

    RxInt? livenessLevel = 0.obs;

    try {
      await facesdkPlugin.setParam({
        'check_liveness_level': livenessLevel.value,
      });
    } catch (e) {
      log("CHECK_LIVENESS_ERROR:$e");
    }

    if (facepluginState.value == -1) {
      warningState.value = "Invalid license!";
      visibleWarning.value = true;
    } else if (facepluginState.value == -2) {
      warningState.value = "License expired!";
      visibleWarning.value = true;
    } else if (facepluginState.value == -3) {
      warningState.value = "Invalid license!";
      visibleWarning.value = true;
    } else if (facepluginState.value == -4) {
      warningState.value = "No activated!";
      visibleWarning.value = true;
    } else if (facepluginState.value == -5) {
      warningState.value = "Init error!";
      visibleWarning.value = true;
    }

    warningStates.value = warningState.value;
    visibleWarnings.value = visibleWarning.value;
  }

  List<EmployeeModel> get filteredEmployees {
    if (searchQuery.value.isEmpty) return employees;
    final q = searchQuery.value.toLowerCase();
    return employees
        .where(
          (e) =>
              e.fullName.toLowerCase().contains(q) ||
              e.employeeCode.toLowerCase().contains(q) ||
              (e.mobile ?? '').contains(q),
        )
        .toList();
  }

  void openForm(
    BuildContext context,
    EmployeeController controller, {
    EmployeeModel? employee,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        // fullscreenDialog: true,
        builder: (_) =>
            EmployeeFormPage(employee: employee, controller: controller),
      ),
    );
  }

  void confirmDelete(BuildContext context, EmployeeController ctrl, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Employee'),
        content: const Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ctrl.deleteEmployee(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> loadEmployees() async {
    isLoading.value = true;
    try {
      employees.value = await _repo.getEmployees(auth.companyId);
    } catch (e) {
      showError('Failed to load employees: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<EmployeeModel?> getEmployee(String id) async {
    try {
      final emp = await _repo.getEmployeeUserId(id);
      return emp;
    } catch (e) {
      showError("Failed to load employee: $e");
    }
    return null;
  }

  // Generate code for a SPECIFIC company (not always the active branch)
  Future<String> generateCode([String? companyId]) =>
      _repo.generateEmployeeCode(companyId ?? auth.companyId);

  Future<void> createEmployee(
    Map<String, dynamic> rawData, {
    Uint8List? profileBytes,
    String? profilePath,
    Uint8List? aadharBytes,
    String? aadharPath,
  }) async {
    isLoading.value = true;
    try {
      // ── Pull out non-column values before sanitising ────
      final String? loginPassword = rawData.remove('password') as String?;
      final String? loginUsername = rawData.remove('username') as String?;

      // ✅ Use company_id from the FORM (selected branch), not always active branch
      final String selectedCompanyId =
          (rawData['company_id'] as String?)?.isNotEmpty == true
          ? rawData['company_id'] as String
          : auth.companyId;
      rawData['company_id'] = selectedCompanyId;

      // ── Upload profile picture ──────────────────────────
      if (kIsWeb) {
        if (profileBytes != null && profileBytes.isNotEmpty) {
          final fileName =
              'profile_${selectedCompanyId}_${rawData['employee_code']}'
              '_${DateTime.now().millisecondsSinceEpoch}.jpg';
          rawData['profile_picture'] = await SupabaseService.uploadFile(
            'profiles',
            fileName,
            profileBytes,
          );
        }
      } else {
        if (selectedProfile.value != null) {
          final bytes = await selectedProfile.value!.readAsBytes();
          final fileName =
              'profile_${selectedCompanyId}_${rawData['employee_code']}'
              '_${DateTime.now().millisecondsSinceEpoch}.jpg';
          rawData['profile_picture'] = await SupabaseService.uploadFile(
            'profiles',
            fileName,
            bytes,
            contentType: 'image/jpeg',
          );
        }
      }

      // ── Upload aadhar / first document ──────────────────
      if (aadharBytes != null && aadharBytes.isNotEmpty) {
        final ext = aadharPath?.split('.').last ?? 'pdf';
        final fileName =
            'doc_${selectedCompanyId}_${rawData['employee_code']}'
            '_${DateTime.now().millisecondsSinceEpoch}.$ext';
        rawData['aadhar_doc_url'] = await SupabaseService.uploadFile(
          'documents',
          fileName,
          aadharBytes,
        );
      }

      // ── Sanitise: remove null FK strings and non-columns ─
      for (final key in ['status_id', 'salary_type_id', 'user_id']) {
        final v = rawData[key];
        if (v == null || v == '') rawData.remove(key);
      }
      // Remove empty optional text fields so DB uses its defaults
      rawData.removeWhere(
        (k, v) =>
            !_employeeCols.contains(k) ||
            (v is String && v.isEmpty && !_requiredCols.contains(k)),
      );

      // ── INSERT into employees ───────────────────────────
      debugPrint(
        '[EmpCtrl] inserting into company $selectedCompanyId: $rawData',
      );
      final emp = await _repo.createEmployee(rawData);
      debugPrint('[EmpCtrl] created: ${emp.id}');

      // ── Optionally create login account ─────────────────
      final email = rawData['email'] as String?;
      final empCode = rawData['employee_code'] as String? ?? '';
      final username = loginUsername?.isNotEmpty == true
          ? loginUsername!
          : empCode;

      if (email != null &&
          email.isNotEmpty &&
          loginPassword != null &&
          loginPassword.isNotEmpty) {
        try {
          await _createOrLinkLoginUser(
            email: email,
            password: loginPassword,
            username: username,
            empId: emp.id,
            companyId: selectedCompanyId, // ✅ use selected branch
            roleId: rawData['role_id'] as String?,
            fullName: rawData['full_name'] as String? ?? '',
          );
        } catch (userErr) {
          debugPrint('[EmpCtrl] login user warning: $userErr');
          showError(
            'Employee saved but login account could not be created: '
            '$userErr\nYou can set credentials later.',
          );
        }
      }

      // ── Reload with joins ───────────────────────────────
      final full = await _repo.getEmployee(emp.id) ?? emp;
      employees.insert(0, full);
      showSuccess('Employee "${emp.fullName}" created successfully');
    } catch (e) {
      debugPrint('[EmpCtrl] createEmployee ERROR: $e');
      showError('Failed to create employee: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Creates a new auth user OR links an existing one to the employee.
  /// Handles the "user_already_exists" case gracefully by looking up
  /// the existing user's ID and linking it to the employee record.
  Future<void> _createOrLinkLoginUser({
    required String email,
    required String password,
    required String? username,
    required String empId,
    required String companyId,
    required String? roleId,
    required String fullName,
  }) async {
    final client = SupabaseService.client;
    String? uid;

    // 1. Try to create a new auth user
    try {
      final authRes = await SupabaseService.auth.signUp(
        email: email,
        password: password,
      );
      uid = authRes.user?.id;
    } catch (signUpErr) {
      final errStr = signUpErr.toString();
      // If user already exists in Supabase Auth, find their existing ID
      if (errStr.contains('user_already_exists') ||
          errStr.contains('already registered') ||
          errStr.contains('422')) {
        debugPrint('[EmpCtrl] Email already in auth, linking existing user');
        // Look up their existing users row
        final existingRow = await client
            .from('users')
            .select('id')
            .eq('email', email)
            .maybeSingle();
        uid = existingRow?['id'] as String?;
        if (uid == null) {
          // User exists in Auth but not in users table — can't link
          throw Exception(
            'Email "$email" is already registered as a different account. '
            'Use a different email for this employee.',
          );
        }
      } else {
        rethrow;
      }
    }

    if (uid == null) return;

    // 2. Upsert the users row (create or update)
    await client.from('users').upsert({
      'id': uid,
      'company_id': companyId,
      'role_id': roleId,
      'employee_id': empId,
      'full_name': fullName,
      'email': email,
      'username': (username?.isNotEmpty == true)
          ? username
          : email.split('@')[0],
      'is_admin': false,
    }, onConflict: 'id');

    // 3. Link auth user to employee record
    await client.from('employees').update({'user_id': uid}).eq('id', empId);

    // 4. Grant access to this company branch for the employee
    try {
      await client.from('user_company_access').upsert({
        'user_id': uid,
        'company_id': companyId,
        'org_id': await _getOrgId(companyId),
        'role_id': roleId,
        'is_default': true,
      }, onConflict: 'user_id,company_id');
    } catch (_) {}

    debugPrint('[EmpCtrl] Login user linked: $uid → employee $empId');
  }

  Future<String?> _getOrgId(String companyId) async {
    try {
      final row = await SupabaseService.client
          .from('companies')
          .select('org_id')
          .eq('id', companyId)
          .maybeSingle();
      return row?['org_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateEmployee(
    String id,
    Map<String, dynamic> rawData, {
    Uint8List? profileBytes,
    String? profilePath,
  }) async {
    isLoading.value = true;
    try {
      rawData.remove('password');
      final String? username = rawData.remove('username') as String?;
      // Use company_id from rawData, fall back to active branch
      final String companyId =
          (rawData['company_id'] as String?)?.isNotEmpty == true
          ? rawData['company_id'] as String
          : auth.companyId;

      if (kIsWeb) {
        if (profileBytes != null && profileBytes.isNotEmpty) {
          final fileName =
              'profile_${companyId}_${rawData['employee_code']}'
              '_${DateTime.now().millisecondsSinceEpoch}.jpg';
          rawData['profile_picture'] = await SupabaseService.uploadFile(
            'profiles',
            fileName,
            profileBytes,
          );
        }
      } else {
        if (selectedProfile.value != null) {
          final bytes = await selectedProfile.value!.readAsBytes();
          final fileName =
              'profile_${companyId}_${rawData['employee_code']}'
              '_${DateTime.now().millisecondsSinceEpoch}.jpg';
          rawData['profile_picture'] = await SupabaseService.uploadFile(
            'profiles',
            fileName,
            bytes,
          );
        }
      }

      for (final key in ['status_id', 'salary_type_id', 'user_id']) {
        final v = rawData[key];
        if (v == null || v == '') rawData.remove(key);
      }
      rawData.removeWhere((k, _) => !_employeeCols.contains(k));
      final emp = await _repo.updateEmployee(id, rawData);
      // Update username in users table if changed
      if (username != null && username.isNotEmpty && emp.userId != null) {
        await SupabaseService.client
            .from('users')
            .update({'username': username})
            .eq('id', emp.userId!);
      }

      final full = await _repo.getEmployee(id) ?? emp;
      final idx = employees.indexWhere((e) => e.id == id);
      if (idx != -1) employees[idx] = full;
      showSuccess('Employee updated');
    } catch (e) {
      debugPrint('[EmpCtrl] updateEmployee ERROR: $e');
      showError('Failed to update employee: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteEmployee(String id) async {
    try {
      await _repo.deleteEmployee(id);
      employees.removeWhere((e) => e.id == id);
      showSuccess('Employee deleted');
    } catch (e) {
      showError('Failed to delete: $e');
    }
  }

  // Columns that must never be removed even if empty string
  static const _requiredCols = {
    'company_id',
    'employee_code',
    'full_name',
    'department_id',
    'role_id',
  };
}
