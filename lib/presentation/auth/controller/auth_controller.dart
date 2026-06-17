// lib/presentation/controllers/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sri_hr/core/constants/app_constants.dart';
import 'package:sri_hr/core/handler/exception_handler.dart';
import 'package:sri_hr/data/models/role_model.dart';
import 'package:sri_hr/data/models/role_permission_model.dart';
import 'package:sri_hr/data/models/subscription_model.dart';
import 'package:sri_hr/data/models/user_model.dart';
import 'package:sri_hr/presentation/auth/repository/auth_repository.dart';
import 'package:sri_hr/presentation/employee/repository/employee_repository.dart';
import 'package:sri_hr/presentation/subscription/repository/subscription_repository.dart';
import 'package:sri_hr/routes/app_routes.dart';

class AuthController extends GetxController {
  final authRepo = AuthRepository();
  final subRepo = SubscriptionRepository();
  final box = GetStorage();

  // Observable state
  final isLoading = false.obs;
  final currentUser = Rxn<UserModel>();
  final currentRole = Rxn<RoleModel>();
  final permissions = <String, RolePermissionModel>{}.obs;
  final subscription = Rxn<SubscriptionModel>();
  final isSubscriptionActive = false.obs;

  // Reactive company ID — updates when branch is switched
  // All controllers must use this instead of currentUser.value?.companyId
  final activeCompanyId = ''.obs;
  final RxString kioskCompId = "".obs;

  final activeOrgId = ''.obs;

  // Computed
  String get companyId => activeCompanyId.value.isNotEmpty
      ? activeCompanyId.value
      : currentUser.value?.companyId ?? '';

  void setActiveCompanyId(String id) => activeCompanyId.value = id;
  String get userId => currentUser.value?.id ?? '';
  String get employeeId => currentUser.value?.employeeId ?? '';
  bool get isAdmin => currentUser.value?.isAdmin ?? false;
  bool get isLoggedIn => currentUser.value != null;

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
  }

  // ── Restore session from storage ────────────
  Future<void> _restoreSession() async {
    final savedUser = box.read('current_user');
    if (savedUser != null) {
      currentUser.value = UserModel.fromJson(savedUser);
      await _loadPermissionsAndSubscription();
      return;
    }
    final kioskId = box.read('kiosk_company_id');
    if (kioskId != null && kioskId.isNotEmpty) {
      kioskCompId.value = kioskId;
      await authRepo.signInKioskSession(); // re-establish session
    }
  }

  // ── Login ────────────────────────────────────
  Future<void> login(String emailOrUsername, String password) async {
    isLoading.value = true;
    try {
      if (!emailOrUsername.contains('@')) {
        final kioskCompanyId = await authRepo.checkKioskLogin(
          emailOrUsername.trim(),
          password.trim(),
        );
        if (kioskCompanyId != null && kioskCompanyId.isNotEmpty) {
          kioskCompId.value = kioskCompanyId;
          // Persist kiosk session so splash can restore it on refresh
          box.write('kiosk_company_id', kioskCompanyId);
          box.remove('current_user'); // ensure normal session is cleared

          await authRepo.signInKioskSession();
          isLoading.value = false;
          Get.offAllNamed(
            AppRoutes.routeKioskAttendance,
            arguments: {'company_id': kioskCompanyId},
          );
          return;
        }
      }

      final userRow = await authRepo.login(emailOrUsername, password);
      final user = UserModel.fromJson(userRow);
      currentUser.value = user;
      final employee = await EmployeeRepository().getEmployeeUserId(user.id);
      if (employee?.mobileLogin != false && employee?.isActive != false) {
        // Set reactive company ID
        activeCompanyId.value = user.companyId;

        // Persist
        box.write('current_user', userRow);

        // Load permissions + subscription
        await _loadPermissionsAndSubscription();

        // Navigate
        if (isSubscriptionActive.value) {
          Get.offAllNamed(AppRoutes.routeDashboard);
        } else {
          Get.offAllNamed(AppRoutes.routeSubscription);
        }
      } else {
        Get.snackbar(
          'Login Failed',
          (employee?.mobileLogin == false || employee?.mobileLogin == null)
              ? "Mobile login is disabled for your account. Please contact your administrator."
              : "Your account has been deactivated. Please contact your administrator.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.amber.shade600,
          colorText: Colors.white,
          icon: const Icon(Icons.error_outline, color: Colors.white),
        );
        logout();
      }
    } catch (e) {
      Get.snackbar(
        'Login Failed',
        handleException(e),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Register ─────────────────────────────────
  Future<void> register({
    required String companyName,
    required String personName,
    required String gstin,
    required String mobile,
    required String email,
    required String address,
    required String country,
    required String state,
    required String city,
    required String pincode,
    required String password,
  }) async {
    isLoading.value = true;
    try {
      await authRepo.registerCompany(
        companyName: companyName,
        personName: personName,
        gstin: gstin,
        mobile: mobile,
        email: email,
        address: address,
        country: country,
        state: state,
        city: city,
        pincode: pincode,
        password: password,
      );
      await logout();
      Get.snackbar(
        'Registration Successful!',
        'Your 3-day free trial has started. Please login.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      Get.offAllNamed(AppRoutes.routeLogin);
    } catch (e) {
      Get.snackbar(
        'Registration Failed',
        handleException(e),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Logout ───────────────────────────────────
  Future<void> logout() async {
    await authRepo.logout();
    currentUser.value = null;
    currentRole.value = null;
    permissions.clear();
    subscription.value = null;
    kioskCompId.value = '';
    box.remove('current_user');
    box.remove('kiosk_company_id');
    Get.offAllNamed(AppRoutes.routeLogin);
  }

  // ── Load permissions + subscription ──────────
  Future<void> _loadPermissionsAndSubscription() async {
    final user = currentUser.value;
    if (user == null) return;

    // Load permissions
    if (user.roleId != null) {
      // Always load role-based permissions — even for admin users.
      // The permission matrix in the designation screen controls what's accessible.
      final perms = await authRepo.getRolePermissions(user.roleId!);
      permissions.value = {
        for (final p in perms.map((r) => RolePermissionModel.fromJson(r)))
          p.module: p,
      };
    } else if (user.isAdmin) {
      // Admin with NO role assigned gets full access to everything
      for (final module in AppConstants.modules) {
        permissions[module] = RolePermissionModel(
          id: '',
          companyId: user.companyId,
          roleId: '',
          module: module,
          canView: true,
          canAdd: true,
          canEdit: true,
          canDelete: true,
        );
      }
    }

    final orgId = await subRepo.getOrgId(user.companyId);
    if (orgId != null && orgId.isNotEmpty) {
      activeOrgId.value = orgId;
      // 2. Find the active subscription for the whole org
      final sub = await subRepo.getActiveSubscriptionByOrg(orgId);
      if (sub != null) {
        subscription.value = sub;
        isSubscriptionActive.value = sub.isActive;
        if (sub.isExpiringSoon) {
          Future.delayed(const Duration(seconds: 2), () {
            Get.snackbar(
              '⚠ Subscription Expiring',
              'Your plan expires in ${sub.daysRemaining} day(s). Renew now!',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.orange.shade700,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
              mainButton: TextButton(
                onPressed: () => Get.toNamed(AppRoutes.routeSubscription),
                child: const Text('Renew', style: TextStyle(color: Colors.white)),
              ),
            );
          });
        }
        return;
      }
    }

    // Load subscription
    final subRow = await authRepo.getSubscription(user.companyId);
    if (subRow != null) {
      subscription.value = SubscriptionModel.fromJson(subRow);
      isSubscriptionActive.value = subscription.value!.isActive;

      // Notify admin if expiring soon
      if (subscription.value!.isExpiringSoon) {
        Future.delayed(const Duration(seconds: 2), () {
          Get.snackbar(
            '⚠ Subscription Expiring',
            'Your plan expires in ${subscription.value!.daysRemaining} day(s). Renew now!',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange.shade700,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
            mainButton: TextButton(
              onPressed: () => Get.toNamed(AppRoutes.routeSubscription),
              child: const Text('Renew', style: TextStyle(color: Colors.white)),
            ),
          );
        });
      }
    }
  }

  // ── Permission helpers ───────────────────────
  bool canView(String module) {
    if (!isSubscriptionActive.value && module != 'subscription') return false;
    return permissions[module]?.canView ?? false;
  }

  bool canAdd(String module) {
    if (!isSubscriptionActive.value) return false;
    return permissions[module]?.canAdd ?? false;
  }

  bool canEdit(String module) {
    if (!isSubscriptionActive.value) return false;
    return permissions[module]?.canEdit ?? false;
  }

  bool canDelete(String module) {
    if (!isSubscriptionActive.value) return false;
    return permissions[module]?.canDelete ?? false;
  }

  List<String> get visibleModules {
    if (!isSubscriptionActive.value) return ['subscription'];
    return AppConstants.modules.where((m) => canView(m)).toList();
  }
}
