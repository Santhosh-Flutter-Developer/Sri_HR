import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:facesdk_plugin/facesdk_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sri_hr/core/constants/app_constants.dart';
import 'package:sri_hr/core/handler/exception_handler.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/employee_model.dart';
import 'package:sri_hr/data/services/connectivity_service.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:sri_hr/data/utils/network_time.dart';
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

  // ── Pagination ───────────────────────────────────────────
  static const rowLimitOptions = [10, 20, 50, 100];
  final rowLimit = 10.obs;
  final currentPage = 0.obs;

  List<EmployeeModel> get paginatedEmployees {
    final list = filteredEmployees;
    final start = currentPage.value * rowLimit.value;
    if (start >= list.length) return [];
    final end = (start + rowLimit.value).clamp(0, list.length);
    return list.sublist(start, end);
  }

  int get totalPages =>
      (filteredEmployees.length / rowLimit.value).ceil().clamp(1, 999999);

  void setRowLimit(int limit) {
    rowLimit.value = limit;
    currentPage.value = 0;
  }

  void goToPage(int page) {
    if (page < 0 || page >= totalPages) return;
    currentPage.value = page;
  }

  dynamic faceTemplate;
  File? faceImage;
  final selectedProfile = Rx<File?>(null);
    final orgEmployeeCount = 0.obs;

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
    'work_start_time',
    'work_end_time',
    'lunch_start_time',
    'lunch_end_time',
    'face_template',
    'is_active',
  };

  @override
  void onInit() {
    super.onInit();
     _registerReload();
    if (!kIsWeb) {
      faceInit();
    }
    loadEmployees();
    loadOrgEmployeeCount();
    // Reset to first page whenever search query changes
    ever(searchQuery, (_) => currentPage.value = 0);
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
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ctrl.deleteEmployee(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _registerReload() {
    try {
      Get.find<ConnectivityService>().register(loadEmployees);
    } catch (_) {}
  }

  Future<void> loadEmployees() async {
    isLoading.value = true;
    try {
    final list = await _repo.getEmployees(auth.companyId);
       list.sort((a, b) => (a.createdAt ?? DateTime(0))
        .compareTo(b.createdAt ?? DateTime(0)));
     employees.value = list; 
    } catch (e) {
      showError(handleException(e));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadOrgEmployeeCount() async {
    try {
      final orgId = auth.activeOrgId.value;
      if (orgId.isNotEmpty) {
        orgEmployeeCount.value = await _repo.countEmployeesByOrg(orgId);
      } else {
        // Fallback: count only current branch (single-branch orgs)
        orgEmployeeCount.value = await _repo.countEmployees(auth.companyId);
      }
    } catch (e) {
      debugPrint('[EmpCtrl] loadOrgEmployeeCount ERROR: $e');
    }
  }

  Future<EmployeeModel?> getEmployee(String id) async {
    try {
      final emp = await _repo.getEmployeeUserId(id);
      return emp;
    } catch (e) {
      showError(handleException(e));
    }
    return null;
  }

  // Preview — for showing in form (doesn't reserve)
  Future<String> previewCode([String? companyId]) =>
      _repo.previewEmployeeCode(companyId ?? auth.companyId);

  // Generate — only called on actual save (reserves the code)
  Future<String> generateCode([String? companyId]) =>
      _repo.generateEmployeeCode(companyId ?? auth.companyId);

  Future<void> createEmployee(
    Map<String, dynamic> rawData, {
    Uint8List? profileBytes,
    String? profilePath,
    List<Map<String, dynamic>>? newDocuments,
  }) async {
    isLoading.value = true;
    try {
      // ── Organisation-wide employee limit check ──────────
      final sub = auth.subscription.value;
      if (sub != null) {
        await loadOrgEmployeeCount(); // refresh before checking
        if (orgEmployeeCount.value >= sub.userLimit) {
          showError(
            'Employee limit reached. Your ${sub.plan.name} plan allows '
            '${sub.userLimit} employees across all branches. '
            'Please upgrade your plan to add more.',
          );
          isLoading.value = false;
          return;
        }
      }
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
              '_${NetworkTime.now().millisecondsSinceEpoch}.jpg';
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
              '_${NetworkTime.now().millisecondsSinceEpoch}.jpg';
          rawData['profile_picture'] = await SupabaseService.uploadFile(
            'profiles',
            fileName,
            bytes,
            contentType: 'image/jpeg',
          );
        }
      }

      // ── Upload all documents ─────────────────────────────
      if (newDocuments != null && newDocuments.isNotEmpty) {
        final List<Map<String, dynamic>> uploadedDocs = [];
        for (int idx = 0; idx < newDocuments.length; idx++) {
          final doc = newDocuments[idx];
          final docBytes = doc['bytes'] as Uint8List?;
          if (docBytes == null || docBytes.isEmpty) continue;
          final docName = doc['name'] as String? ?? 'document_$idx';
          final ext = docName.contains('.') ? docName.split('.').last : 'pdf';
          final fileName =
              'doc_${selectedCompanyId}_${rawData['employee_code']}'
              '_${NetworkTime.now().millisecondsSinceEpoch}_$idx.$ext';
          final url = await SupabaseService.uploadFile(
            'documents',
            fileName,
            docBytes,
            contentType: _mimeType(ext),
          );
          // First doc goes to aadhar_doc_url for legacy compatibility
          if (idx == 0) rawData['aadhar_doc_url'] = url;
          uploadedDocs.add({'name': docName, 'url': url});
        }
        // Store all docs as JSON array in other_doc_url
        if (uploadedDocs.isNotEmpty) {
          rawData['other_doc_url'] = jsonEncode(uploadedDocs);
        }
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
            'Employee saved but login account could not be created. You can set credentials later.',
          );
        }
      }

      // ── Reload with joins ───────────────────────────────
      final full = await _repo.getEmployee(emp.id) ?? emp;
      employees.add(full);
      await loadOrgEmployeeCount(); // keep org count in sync
      showSuccess('Employee "${emp.fullName}" created successfully');
    } catch (e) {
      debugPrint('[EmpCtrl] createEmployee ERROR: $e');
       showError(handleException(e));
    } finally {
      isLoading.value = false;
    }
  }

  /// Returns a basic MIME type string for common document extensions.
  String _mimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument'
            '.wordprocessingml.document';
      default:
        return 'application/octet-stream';
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
    List<Map<String, dynamic>>? newDocuments,
    List<Map<String, dynamic>>? savedDocuments,
  }) async {
    isLoading.value = true;
    try {
      // ── Pull out non-column values ──────────────────────
      final String? newPassword = rawData.remove('password') as String?;
      final String? username = rawData.remove('username') as String?;

      final String companyId =
          (rawData['company_id'] as String?)?.isNotEmpty == true
          ? rawData['company_id'] as String
          : auth.companyId;

      // ── Upload profile picture ──────────────────────────
      if (kIsWeb) {
        if (profileBytes != null && profileBytes.isNotEmpty) {
          final fileName =
              'profile_${companyId}_${rawData['employee_code']}'
              '_${NetworkTime.now().millisecondsSinceEpoch}.jpg';
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
              '_${NetworkTime.now().millisecondsSinceEpoch}.jpg';
          rawData['profile_picture'] = await SupabaseService.uploadFile(
            'profiles',
            fileName,
            bytes,
          );
        }
      }

      // ── Upload new documents and merge with saved ones ───
      // Start with already-saved docs (they have 'url' key)
      final List<Map<String, dynamic>> allDocs = [
        if (savedDocuments != null)
          ...savedDocuments.map((d) => {'name': d['name'], 'url': d['url']}),
      ];

      if (newDocuments != null && newDocuments.isNotEmpty) {
        for (int idx = 0; idx < newDocuments.length; idx++) {
          final doc = newDocuments[idx];
          final docBytes = doc['bytes'] as Uint8List?;
          if (docBytes == null || docBytes.isEmpty) continue;
          final docName = doc['name'] as String? ?? 'document_$idx';
          final ext =
              docName.contains('.') ? docName.split('.').last : 'pdf';
          final fileName =
              'doc_${companyId}_${rawData['employee_code']}'
              '_${NetworkTime.now().millisecondsSinceEpoch}_$idx.$ext';
          final url = await SupabaseService.uploadFile(
            'documents',
            fileName,
            docBytes,
            contentType: _mimeType(ext),
          );
          allDocs.add({'name': docName, 'url': url});
        }
      }

      // Write back to rawData columns
      if (allDocs.isNotEmpty) {
        // First doc → aadhar_doc_url (legacy)
        rawData['aadhar_doc_url'] = allDocs.first['url'] as String;
        // All docs → other_doc_url as JSON
        rawData['other_doc_url'] = jsonEncode(allDocs);
      } else {
        // No docs left (user removed all) — clear the fields
        rawData['aadhar_doc_url'] = null;
        rawData['other_doc_url'] = null;
      }

      // ── Sanitise rawData ────────────────────────────────
      for (final key in ['status_id', 'salary_type_id', 'user_id']) {
        final v = rawData[key];
        if (v == null || v == '') rawData.remove(key);
      }
      rawData.removeWhere((k, _) => !_employeeCols.contains(k));

      // ── Update employees table ──────────────────────────
      final emp = await _repo.updateEmployee(id, rawData);

      // ── Update users table (username + email) ───────────
      if (emp.userId != null) {
        final userUpdates = <String, dynamic>{};
        if (username != null && username.isNotEmpty) {
          userUpdates['username'] = username;
        }
        final newEmail = rawData['email'] as String?;
        if (newEmail != null && newEmail.isNotEmpty) {
          userUpdates['email'] = newEmail;
        }
        if (userUpdates.isNotEmpty) {
          await SupabaseService.client
              .from('users')
              .update(userUpdates)
              .eq('id', emp.userId!);
        }

        // ── Update Supabase Auth (email + password) ─────────
        // This is what actually fixes login credentials
        await _updateAuthUser(
          userId: emp.userId!,
          newEmail: newEmail,
          newPassword: (newPassword != null && newPassword.isNotEmpty)
              ? newPassword
              : null,
        );
      }

      final full = await _repo.getEmployee(id) ?? emp;
      final idx = employees.indexWhere((e) => e.id == id);
      if (idx != -1) employees[idx] = full;
      showSuccess('Employee updated');
    } catch (e) {
      debugPrint('[EmpCtrl] updateEmployee ERROR: $e');
      showError(handleException(e));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateAuthUser({
    required String userId,
    String? newEmail,
    String? newPassword,
  }) async {
    if (newEmail == null && newPassword == null) return;

    try {
      await SupabaseService.client.rpc(
        'update_auth_user',
        params: {
          'p_user_id': userId,
          if (newEmail != null && newEmail.isNotEmpty) 'p_email': newEmail,
          if (newPassword != null && newPassword.isNotEmpty)
            'p_password': newPassword,
        },
      );
      debugPrint('[EmpCtrl] Auth user updated for $userId');
    } catch (e) {
      debugPrint('[EmpCtrl] _updateAuthUser ERROR: $e');
      showError(
        'Employee data saved, but login credentials could not be updated. Please try again.',
      );
    }
  }

  Future<bool> isMobileExists(
    String mobile, {
    String? excludeEmployeeId,
  }) async {
    try {
      return await _repo.isMobileExists(
        mobile,
        excludeEmployeeId: excludeEmployeeId,
      );
    } catch (e) {
      debugPrint('[EmpCtrl] isMobileExists ERROR: $e');
      return false;
    }
  }

  Future<bool> isEmailExists(String email, {String? excludeEmployeeId}) async {
    try {
      return await _repo.isEmailExists(
        email,
        excludeEmployeeId: excludeEmployeeId,
      );
    } catch (e) {
      debugPrint('[EmpCtrl] isEmailExists ERROR: $e');
      return false;
    }
  }

  Future<void> deleteEmployee(String id) async {
    try {
      // 1. Get employee first to retrieve userId before deleting
      final emp = employees.firstWhereOrNull((e) => e.id == id);

      // 2. Delete from employees table
      await _repo.deleteEmployee(id);

      // 3. Delete from auth.users so they can no longer login
      if (emp?.userId != null) {
        try {
          await SupabaseService.client.rpc(
            'delete_auth_user',
            params: {'p_user_id': emp!.userId!},
          );
          debugPrint('[EmpCtrl] Auth user deleted: ${emp.userId}');
        } catch (e) {
          debugPrint('[EmpCtrl] Auth user delete warning: $e');
          // Employee is deleted from DB, just auth cleanup failed
           showError(handleException(e));
        }
      }

      employees.removeWhere((e) => e.id == id);
      await loadOrgEmployeeCount(); 
      showSuccess('Employee deleted');
    } catch (e) {
      showError(handleException(e));
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