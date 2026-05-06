import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/company_model.dart';
import 'package:sri_hr/data/models/role_permission_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/company/ui/add_branch_form.dart';
import 'package:sri_hr/presentation/dashboard/controller/dashboard_controller.dart';
import 'package:sri_hr/presentation/department/controller/department_controller.dart';
import 'package:sri_hr/presentation/designation/controller/role_controller.dart';
import 'package:sri_hr/presentation/employee/controller/employee_controller.dart';
import 'package:sri_hr/presentation/employee_status/controller/employee_status_controller.dart';
import 'package:sri_hr/presentation/helper/helper.dart';
import 'package:sri_hr/presentation/holiday/controller/holiday_controller.dart';
import 'package:sri_hr/presentation/leave/controller/leave_controller.dart';
import 'package:sri_hr/presentation/permission_request/controller/permission_request_controller.dart';
import 'package:sri_hr/presentation/salary_type/controller/salary_type_controller.dart';
import 'package:sri_hr/widgets/sri_button.dart';

AuthController get auth => Get.find<AuthController>();

class CompanyController extends GetxController {
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

    ever(auth.currentUser, (u) {
      if (u != null && companies.isEmpty) {
        loadAllCompanies();
      }
    });
    if (auth.companyId.isNotEmpty) {
      loadAllCompanies();
    }
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
      showError('Failed to load companies: $e');
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
      if (oid == null) throw Exception('Organization not found');
      await client.rpc(
        'add_company_branch',
        params: {
          'p_org_id': oid,
          'p_company_name': data['name'],
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
      showError('Failed to add branch: $e');
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
            'logo_${cid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
      showSuccess('Company updated');
    } catch (e) {
      showError('Failed to update: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Delete a branch ──────────────────────────────────────
  Future<void> deleteBranch(String companyId) async {
    if (companies.length <= 1) {
      showError('Cannot delete the only company');
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
      showError('Failed to delete: $e');
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
