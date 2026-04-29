import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sri_hr/core/constants/app_constants.dart';
import 'package:sri_hr/data/models/role_model.dart';
import 'package:sri_hr/data/models/role_permission_model.dart';
import 'package:sri_hr/data/models/subscription_model.dart';
import 'package:sri_hr/data/models/user_model.dart';
import 'package:sri_hr/data/services/subscription_repository.dart';
import 'package:sri_hr/presentation/auth/repository/auth_repository.dart';
import 'package:sri_hr/routes/app_routes.dart';

class AuthController extends GetxController {
  final authRepo = AuthRepository();
  final subRepo = SubscriptionRepository();

  final box = GetStorage();

  final isLoading = false.obs;
  final currentUser = Rxn<UserModel>();
  final currentRole = Rxn<RoleModel>();
  final permissions = <String, RolePermissionModel>{}.obs;
  final subscription = Rxn<SubscriptionModel>();
  final isSubscriptionActive = false.obs;

  String get companyId => currentUser.value?.companyId ?? '';
  String get userId => currentUser.value?.id ?? '';
  bool get isAdmin => currentUser.value?.isAdmin ?? false;
  bool get isLoggedIn => currentUser.value != null;

  @override
  void onInit() {
    super.onInit();
    restoreSession();
  }

  // ── Restore session from storage ────────────
  Future<void> restoreSession() async {
    final savedUser = box.read('current_user');
    if (savedUser != null) {
      currentUser.value = UserModel.fromJson(savedUser);
      await loadPermissionsAndSubscription();
    }
  }

  // ── Login ────────────────────────────────────
  Future<void> login(String emailOrUsername, String password) async {
    isLoading.value = true;
    try {
      final userRow = await authRepo.login(emailOrUsername, password);
      final user = UserModel.fromJson(userRow);
      currentUser.value = user;

      // Persist
      box.write('current_user', userRow);

      // Load permissions + subscription
      await loadPermissionsAndSubscription();

      // Navigate
      Get.offAllNamed(AppRoutes.routeDashboard);
    } on Exception catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'Login Failed',
        msg,
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

      Get.snackbar(
        'Registration Successful!',
        'Your 3-day free trial has started. Please login.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      Get.offAllNamed(AppRoutes.routeLogin);
    } on Exception catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'Registration Failed',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
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
    box.remove('current_user');
    Get.offAllNamed(AppRoutes.routeLogin);
  }

  // ── Load permissions + subscription ──────────
  Future<void> loadPermissionsAndSubscription() async {
    final user = currentUser.value;
    if (user == null) return;

    // Load permissions
    if (user.roleId != null) {
      final perms = await authRepo.getRolePermissions(user.roleId!);
      permissions.value = {
        for (final p in perms.map((r) => RolePermissionModel.fromJson(r)))
          p.module: p,
      };
    } else if (user.isAdmin) {
      // Admin gets all permissions
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
    if (isAdmin) return true;
    return permissions[module]?.canView ?? false;
  }

  bool canAdd(String module) {
    if (!isSubscriptionActive.value) return false;
    if (isAdmin) return true;
    return permissions[module]?.canAdd ?? false;
  }

  bool canEdit(String module) {
    if (!isSubscriptionActive.value) return false;
    if (isAdmin) return true;
    return permissions[module]?.canEdit ?? false;
  }

  bool canDelete(String module) {
    if (!isSubscriptionActive.value) return false;
    if (isAdmin) return true;
    return permissions[module]?.canDelete ?? false;
  }

  List<String> get visibleModules {
    if (!isSubscriptionActive.value) return ['subscription'];
    return AppConstants.modules.where((m) => canView(m)).toList();
  }
}
