import 'dart:developer';

import 'package:get/get.dart';
import 'package:sri_hr/data/models/subscription_model.dart';
import 'package:sri_hr/data/utils/network_time.dart';
import 'package:sri_hr/presentation/helper/helper.dart';
import 'package:sri_hr/presentation/subscription/repository/subscription_repository.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';

AuthController get auth => Get.find<AuthController>();

class SubscriptionController extends GetxController {
  final repo = SubscriptionRepository();
  final subscription = Rxn<SubscriptionModel>();
  final plans = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isPaymentProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      subscription.value = await repo.getActiveSubscription(auth.companyId);
      plans.value = await repo.getPlans();
    } catch (e) {
      log("ERROR: $e");
    } finally {
      isLoading.value = false;
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

      final sub = await repo.createSubscription({
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
      });

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
      // Update auth controller
      final authCtrl = Get.find<AuthController>();
      authCtrl.subscription.value = sub;
      authCtrl.isSubscriptionActive.value = true;

      showSuccess(
        'Subscription activated! Enjoy ${duration == 'yearly' ? '1 Year' : '30 Days'} of Sri HR.',
      );
    } catch (e) {
      showError('Subscription failed: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
