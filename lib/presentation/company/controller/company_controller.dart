import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/handler/exception_handler.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/company_model.dart';
import 'package:sri_hr/data/models/role_permission_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:sri_hr/data/utils/network_time.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/company/repository/company_repository.dart';
import 'package:sri_hr/presentation/company/ui/add_branch_form.dart';
import 'package:sri_hr/presentation/dashboard/controller/dashboard_controller.dart';
import 'package:sri_hr/presentation/department/controller/department_controller.dart';
import 'package:sri_hr/presentation/designation/controller/role_controller.dart';
import 'package:sri_hr/presentation/employee/controller/employee_controller.dart';
import 'package:sri_hr/presentation/employee_status/controller/employee_status_controller.dart';
import 'package:sri_hr/data/helper/helper.dart';
import 'package:sri_hr/presentation/holiday/controller/holiday_controller.dart';
import 'package:sri_hr/presentation/leave/controller/leave_controller.dart';
import 'package:sri_hr/presentation/permission_request/controller/permission_request_controller.dart';
import 'package:sri_hr/presentation/salary_type/controller/salary_type_controller.dart';
import 'package:sri_hr/widgets/sri_button.dart';
import 'package:sri_hr/data/services/connectivity_service.dart';

AuthController get auth => Get.find<AuthController>();

class CompanyController extends GetxController {
  final repo = CompanyRepository();
  final client = SupabaseService.client;
  final RxBool enable = false.obs;
  final companies = <CompanyModel>[].obs;
  final activeCompany = Rxn<CompanyModel>();
  Rxn<CompanyModel> get company => activeCompany;

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  String? orgId;

  @override
  void onInit() {
    super.onInit();
    _registerReload();

    ever(auth.currentUser, (u) {
      if (u != null && companies.isEmpty) {
        loadAllCompanies();
      }
    });
    if (auth.companyId.isNotEmpty) {
      loadAllCompanies();
    }
  }


  void _registerReload() {
    try {
      Get.find<ConnectivityService>().register(loadAllCompanies);
    } catch (_) {}
  }
  Future<void> loadAllCompanies() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final uid = client.auth.currentUser?.id;
      if (uid == null) {
        return;
      }

      List<dynamic> accessRows = [];

      try {
        accessRows = await client
            .from('user_company_access')
            .select('company_id,org_id,is_default')
            .eq('user_id', uid);
      } catch (_) {}

      if (accessRows.isNotEmpty) {
        orgId = accessRows.first['org_id'] as String?;
        final ids = accessRows.map((r) => r["company_id"] as String).toList();
        final rows = await client
            .from('companies')
            .select('*')
            .inFilter('id', ids)
            .order('created_at');

        companies.value = rows
            .map<CompanyModel>((r) => CompanyModel.fromJson(r))
            .toList();
      } else {
        final userRow = await client
            .from('users')
            .select('company_id')
            .eq('id', uid)
            .maybeSingle();
        final cid = userRow?['company_id'] as String?;
        if (cid != null) {
          final row = await client
              .from('companies')
              .select('*')
              .eq('id', cid)
              .maybeSingle();

          if (row != null) {
            companies.value = [CompanyModel.fromJson(row)];
          }
        }
      }

      if (companies.isNotEmpty) {
        final current = companies.firstWhere(
          (c) => c.id == auth.companyId,
          orElse: () => companies.first,
        );
        activeCompany.value = current;
        // Ensure auth controller reflects current branch
        auth.setActiveCompanyId(current.id);
      }
    } catch (e) {
      errorMessage.value = e.toString();
      showError(handleException(e));
    } finally {
      isLoading.value = false;
    }
  }

  // ── Switch active branch ─────────────────────────────────
  Future<void> switchCompany(CompanyModel target) async {
    activeCompany.value = target;

    // ❶ Update the reactive companyId in AuthController
    //    All other controllers read _auth.companyId → they get the new value
    auth.setActiveCompanyId(target.id);

    // ❷ Reload permissions for this branch
    final uid = client.auth.currentUser?.id;
    if (uid != null) {
      try {
        final accessRow = await client
            .from('user_company_access')
            .select('role_id')
            .eq('user_id', uid)
            .eq('company_id', target.id)
            .maybeSingle();
        final roleId = accessRow?['role_id'] as String?;
        if (roleId != null) {
          final perms = await client
              .from('role_permissions')
              .select()
              .eq('role_id', roleId);
          auth.permissions.value = {
            for (final p in perms)
              p['module'] as String: RolePermissionModel.fromJson(p),
          };
        }
      } catch (e) {
        debugPrint('[CompanyCtrl] permission reload error: $e');
      }
    }

    // ❸ Reload all HR data controllers for the new branch
    reloadAllControllers();

    Get.snackbar(
      'Branch Switched',
      'Now managing: ${target.name}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void reloadAllControllers() {
    // Reload each controller that's currently registered
    tryReload<DepartmentController>((c) => c.loadDepartments());
    tryReload<RoleController>((c) => c.loadRoles());
    tryReload<EmployeeStatusController>((c) => c.load());
    tryReload<SalaryTypeController>((c) => c.load());
    tryReload<EmployeeController>((c) => c.loadEmployees());
    tryReload<HolidayController>((c) => c.loadHolidays());
    tryReload<LeaveController>((c) => c.loadLeaves());
    tryReload<PermissionRequestController>((c) => c.load());
    tryReload<AttendanceController>((c) => c.loadLogs());
    tryReload<DashboardController>((c) => c.loadStats());
  }

  void tryReload<T extends GetxController>(void Function(T) fn) {
    try {
      if (Get.isRegistered<T>()) fn(Get.find<T>());
    } catch (_) {}
  }

  // ── Add new branch ───────────────────────────────────────
  Future<void> addBranch(Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      final oid = orgId ?? await getOrgId();
      if (oid == null) throw Exception('Organisation record not found. Please contact support.');
      await client.rpc(
        'add_company_branch',
        params: {
          'p_org_id': oid,
          'p_company_name': data['name']??null,
          'p_branch_code': data['branch_code'],
          'p_gstin': data['gstin'],
          'p_phone': data['phone'],
          'p_email': data['email'],
          'p_address': data['address'],
          'p_country': data['country'],
          'p_state': data['state'],
          'p_city': data['city'],
          'p_pincode': data['pincode'],
        },
      );
      await loadAllCompanies();
      showSuccess('Branch "${data['name']}" added successfully');
    } catch (e) {
      showError(handleException(e));
    } finally {
      isLoading.value = false;
    }
  }

  // ── Update active company ────────────────────────────────
  Future<void> updateCompany(
    Map<String, dynamic> data, {
    String? logoPath,
    Uint8List? logoBytes,
  }) async {
    final cid = activeCompany.value?.id ?? auth.companyId;
    if (cid.isEmpty) return;
    isLoading.value = true;
    try {
      if (logoBytes != null && logoBytes.isNotEmpty) {
        final fileName =
            'logo_${cid}_${NetworkTime.now().millisecondsSinceEpoch}.jpg';
        data['logo_url'] = await SupabaseService.uploadFile(
          'logos',
          fileName,
          logoBytes,
        );
      }
      final row = await client
          .from('companies')
          .update(data)
          .eq('id', cid)
          .select()
          .single();
      final updated = CompanyModel.fromJson(row);
      activeCompany.value = updated;
      final idx = companies.indexWhere((c) => c.id == cid);
      if (idx != -1) companies[idx] = updated;
     
    } catch (e) {
      showError(handleException(e));
    } finally {
      isLoading.value = false;
    }
  }

  // ── Delete a branch ──────────────────────────────────────
  Future<void> deleteBranch(String companyId) async {
    if (companies.length <= 1) {
      showError('You cannot delete the only branch. Add another branch first, then delete this one.');
      return;
    }
    try {
      await client.from('companies').delete().eq('id', companyId);
      companies.removeWhere((c) => c.id == companyId);
      if (activeCompany.value?.id == companyId) {
        await switchCompany(companies.first);
      }
      showSuccess('Branch deleted');
    } catch (e) {
      showError(handleException(e));
    }
  }

  Future<String?> getOrgId() async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await client
        .from('user_company_access')
        .select('org_id')
        .eq('user_id', uid)
        .limit(1)
        .maybeSingle();
    return row?['org_id'] as String?;
  }

  // Reload for single-company mode (backward compat)
  Future<void> loadCompany() => loadAllCompanies();

  void showAddBranchDialog(BuildContext context, CompanyController controller) {
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.all(4.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: AddBranchForm(controller: controller),
      ),
      barrierDismissible: false,
    );
  }

  Future<CompanyModel?> getCompany(String id) async {
    try {
      final comp = await repo.getCompany(id);
      return comp;
    } catch (e) {
      showError(handleException(e));
    }
    return null;
  }

  // ── Duplicate field checks (used by Add & Edit forms) ────

  Future<bool> isBranchNameExists(
    String name, {
    String? excludeCompanyId,
  }) async {
    try {
      final oid = orgId ?? await getOrgId();
      if (oid == null) return false;
      return await repo.isBranchNameExists(
        name,
        oid,
        excludeCompanyId: excludeCompanyId,
      );
    } catch (e) {
      debugPrint('[CompanyCtrl] isBranchNameExists ERROR: $e');
      return false;
    }
  }

  Future<bool> isBranchCodeExists(
    String branchCode, {
    String? excludeCompanyId,
  }) async {
    try {
      final oid = orgId ?? await getOrgId();
      if (oid == null) return false;
      return await repo.isBranchCodeExists(
        branchCode,
        oid,
        excludeCompanyId: excludeCompanyId,
      );
    } catch (e) {
      debugPrint('[CompanyCtrl] isBranchCodeExists ERROR: $e');
      return false;
    }
  }

  /// Global: GSTIN must be unique across ALL companies.
  Future<bool> isGstinExists(
    String gstin, {
    String? excludeCompanyId,
  }) async {
    try {
      return await repo.isGstinExists(
        gstin,
        excludeCompanyId: excludeCompanyId,
      );
    } catch (e) {
      debugPrint('[CompanyCtrl] isGstinExists ERROR: $e');
      return false;
    }
  }

  Future<bool> isBranchPhoneExists(
    String phone, {
    String? excludeCompanyId,
  }) async {
    try {
      final oid = orgId ?? await getOrgId();
      if (oid == null) return false;
      return await repo.isBranchPhoneExists(
        phone,
        oid,
        excludeCompanyId: excludeCompanyId,
      );
    } catch (e) {
      debugPrint('[CompanyCtrl] isBranchPhoneExists ERROR: $e');
      return false;
    }
  }

  Future<bool> isBranchEmailExists(
    String email, {
    String? excludeCompanyId,
  }) async {
    try {
      final oid = orgId ?? await getOrgId();
      if (oid == null) return false;
      return await repo.isBranchEmailExists(
        email,
        oid,
        excludeCompanyId: excludeCompanyId,
      );
    } catch (e) {
      debugPrint('[CompanyCtrl] isBranchEmailExists ERROR: $e');
      return false;
    }
  }

  /// Global: phone must be unique across ALL companies + ALL employees.
  Future<bool> isPhoneGloballyExists(
    String phone, {
    String? excludeCompanyId,
  }) async {
    try {
      return await repo.isPhoneGloballyExists(
        phone,
        excludeCompanyId: excludeCompanyId,
      );
    } catch (e) {
      debugPrint('[CompanyCtrl] isPhoneGloballyExists ERROR: $e');
      return false;
    }
  }

  /// Global: email must be unique across ALL companies + ALL employees.
  Future<bool> isEmailGloballyExists(
    String email, {
    String? excludeCompanyId,
  }) async {
    try {
      return await repo.isEmailGloballyExists(
        email,
        excludeCompanyId: excludeCompanyId,
      );
    } catch (e) {
      debugPrint('[CompanyCtrl] isEmailGloballyExists ERROR: $e');
      return false;
    }
  }

  // ── Kiosk / Without-Login ────────────────────────────────

  /// Save kiosk settings (without_login toggle, language, username + password).
  /// If [withoutLogin] is false, clears kiosk credentials from DB via RPC.
  /// If [withoutLogin] is true:
  ///   - First time (no existing kiosk_username): calls set_kiosk_credentials
  ///   - Updating (existing kiosk_username): calls update_kiosk_settings
  ///     (password is optional — blank = keep existing)
  Future<void> saveKioskSettings({
    required String companyId,
    required bool withoutLogin,
    required String language,
    String? kioskUsername,
    String? kioskPassword,
    bool isFirstTime = true, // true = set_kiosk_credentials, false = update_kiosk_settings
  }) async {
    isLoading.value = true;
    try {
      if (!withoutLogin) {
        // Disable: clear credentials via RPC
        await client.rpc('disable_kiosk', params: {
          'p_company_id': companyId,
          'p_language': language,
        });
      } else if (isFirstTime) {
        // First-time enable: password is required
        await client.rpc('set_kiosk_credentials', params: {
          'p_company_id': companyId,
          'p_username': kioskUsername,
          'p_password': kioskPassword,
          'p_language': language,
        });
      } else {
        // Update existing kiosk: password optional
        await client.rpc('update_kiosk_settings', params: {
          'p_company_id': companyId,
          'p_username': kioskUsername,
          'p_language': language,
          'p_password': kioskPassword, // null = keep existing
        });
      }
      await loadAllCompanies();
       showSuccess('Company updated Successfully');
    } catch (e) {
      // Show meaningful error from RPC (e.g. username already taken)
      final msg = e.toString().replaceAll('Exception: ', '');
      showError(msg);
    } finally {
      isLoading.value = false;
    }
  }

  /// Returns true if username is free globally
  /// (not in users.username AND not in another company's kiosk_username).
  Future<bool> isKioskUsernameAvailable(
    String username,
    String currentCompanyId,
  ) async {
    try {
      final result = await client.rpc(
        'check_kiosk_username_available',
        params: {
          'p_username': username,
          'p_company_id': currentCompanyId,
        },
      );
      return result == true;
    } catch (e) {
      return false;
    }
  }

  void confirmSwitch(
    BuildContext context,
    CompanyController controller,
    CompanyModel c,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text('Switch Branch'),
        content: Text(
          'Switch all HR operations to "${c.name}"?\n\n'
          'This changes the active branch for employees,'
          'attendance, and all modules.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Just View')),
          SriButton(
            label: 'Switch & Operate',
            onPressed: () {
              Get.back();
              controller.switchCompany(c);
            },
          ),
        ],
      ),
    );
  }

  void confirmDelete(
    BuildContext context,
    CompanyController controller,
    CompanyModel c,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text('Delete Branch'),
        content: Text(
          'Delete "${c.name}"? All employees and data for '
          'this branch will be permanently deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          SriButton(
            label: "Delete",
            color: AppColors.error,
            onPressed: () {
              Get.back();
              controller.deleteBranch(c.id);
            },
          ),
        ],
      ),
    );
  }

  Widget initials(CompanyModel c) => Center(
    child: Text(
      c.name.substring(0, c.name.length > 1 ? 2 : 1).toUpperCase(),
      style: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
    ),
  );

  Widget row2(Widget left, Widget right) => Row(
    children: [
      Expanded(child: left),
      const SizedBox(width: 14),
      Expanded(child: right),
    ],
  );

  Widget logoPlaceholder(CompanyModel c) => Center(
    child: Text(
      c.name.substring(0, c.name.length > 2 ? 2 : 1).toUpperCase(),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 22,
      ),
    ),
  );
}