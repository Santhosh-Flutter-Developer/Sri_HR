import 'package:get/get.dart';
import 'package:sri_hr/core/handler/exception_handler.dart';
import 'package:sri_hr/data/models/subscription_model.dart';
import 'package:sri_hr/data/utils/network_time.dart';
import 'package:sri_hr/data/helper/helper.dart';
import 'package:sri_hr/presentation/employee/repository/employee_repository.dart';
import 'package:sri_hr/presentation/subscription/repository/subscription_repository.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/data/services/connectivity_service.dart';

AuthController get auth => Get.find<AuthController>();

class SubscriptionController extends GetxController {
  final repo = SubscriptionRepository();
  final employeeRepo = EmployeeRepository();
  final subscription = Rxn<SubscriptionModel>();
  final plans = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final usedSeats = 0.obs;
  final isPaymentProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();
    _registerReload();
    load();
  }

  int get availableSeats {
    final limit = subscription.value?.userLimit ?? 0;
    return (limit - usedSeats.value).clamp(0, limit);
  }


  void _registerReload() {
    try {
      Get.find<ConnectivityService>().register(load);
    } catch (_) {}
  }
  Future<void> load() async {
    isLoading.value = true;
    try {
      // Prefer org-level subscription; fall back to branch-level
      final orgId = auth.activeOrgId.value;
      if (orgId.isNotEmpty) {
        subscription.value = await repo.getActiveSubscriptionByOrg(orgId);
      }
      subscription.value ??= await repo.getActiveSubscription(auth.companyId);
      plans.value = await repo.getPlans();
      await loadUsedSeats();
    } catch (e) {
      showError(handleException(e));
    } finally {
      isLoading.value = false;
    }
  }

  /// Refreshes the count of active employees using a seat (org-wide,
  /// falling back to the current branch for single-branch companies).
  Future<void> loadUsedSeats() async {
    try {
      final orgId = auth.activeOrgId.value;
      if (orgId.isNotEmpty) {
        usedSeats.value = await employeeRepo.countEmployeesByOrg(orgId);
      } else {
        usedSeats.value = await employeeRepo.countEmployees(auth.companyId);
      }
    } catch (e) {
      showError(handleException(e));
    }
  }

  Future<void> activatePlan({
    required String planName,
    required int userLimit,
    required String duration,
    required double amount,
    required String paymentId,
  }) async {
    isLoading.value = true;
    try {
      final now = NetworkTime.now();
    final days = duration == 'yearly' ? 365 : 30;
    final expiry = now.add(Duration(days: days));

    // Check if a subscription already exists for this company
    final existing = await repo.getActiveSubscription(auth.companyId);

    final subData = {
      'company_id': auth.companyId,
      'plan': planName,
      'status': 'active',
      'user_limit': userLimit,
      'start_date': now.toIso8601String().substring(0, 10),
      'expiry_date': expiry.toIso8601String().substring(0, 10),
      'payment_id': paymentId,
      'payment_status': 'paid',
      'amount': amount,
      'duration': duration,
    };

    SubscriptionModel sub;
    if (existing != null) {
      // UPDATE the existing row instead of inserting a new one
      sub = await repo.updateSubscription(existing.id, subData);
    } else {
      sub = await repo.createSubscription(subData);
    }

      await repo.recordPayment({
        'company_id': auth.companyId,
        'subscription_id': sub.id,
        'payment_id': paymentId,
        'amount': amount,
        'currency': 'INR',
        'status': 'paid',
        'gateway': 'razorpay',
      });

      subscription.value = sub;
      await loadUsedSeats();
      // Update auth controller
      final authCtrl = Get.find<AuthController>();
      authCtrl.subscription.value = sub;
      authCtrl.isSubscriptionActive.value = true;

      showSuccess(
        'Subscription activated! Enjoy ${duration == 'yearly' ? '1 Year' : '30 Days'} of Punch App.',
      );
    } catch (e) {
      showError(handleException(e));
    } finally {
      isLoading.value = false;
    }
  }
}