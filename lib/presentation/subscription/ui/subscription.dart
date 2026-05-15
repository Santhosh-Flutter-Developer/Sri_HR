import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
// import 'package:razorpay_web/razorpay_flutter_web.dart' hide Razorpay;
import 'package:razorpay_web/razorpay_web.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/utils/network_time.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/subscription/controller/subscription_controller.dart';
import 'package:sri_hr/presentation/subscription/widgets/current_plan_card.dart';
import 'package:sri_hr/presentation/subscription/widgets/duration_toggle.dart';
import 'package:sri_hr/presentation/subscription/widgets/payment_info.dart';
import 'package:sri_hr/presentation/subscription/widgets/plans_grid.dart';
import 'package:sri_hr/widgets/app_shell.dart';
import 'package:sri_hr/widgets/empty_state.dart';
import 'package:sri_hr/widgets/loading_overlay.dart';

class Subscription extends StatefulWidget {
  const Subscription({super.key});

  @override
  State<Subscription> createState() => _SubscriptionState();
}

class _SubscriptionState extends State<Subscription> {
  final controller = Get.isRegistered<SubscriptionController>()
      ? Get.find<SubscriptionController>()
      : Get.put(SubscriptionController());
  late Razorpay razorpay;
  Map<String, dynamic>? selectedPlan;
  String selectedDuration = 'monthly';

  @override
  void initState() {
    super.initState();
    razorpay = Razorpay();
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
  }

  @override
  void dispose() {
    razorpay.clear();
    super.dispose();
  }

  void handlePaymentSuccess(PaymentSuccessResponse res) {
    if (selectedPlan == null) return;
    final amount = selectedDuration == 'yearly'
        ? (selectedPlan!['yearly_price'] as num).toDouble()
        : (selectedPlan!['monthly_price'] as num).toDouble();
    controller.activatePlan(
      planName: (selectedPlan!['name'] as String),
      userLimit: selectedPlan!['user_limit'] as int,
      duration: selectedDuration,
      amount: amount,
      paymentId:
          res.paymentId ?? 'pay_${NetworkTime.now().millisecondsSinceEpoch}',
    );
  }

  void handlePaymentError(PaymentFailureResponse res) {
    Get.snackbar(
      'Payment Failed',
      res.code.toString() == "2"
          ? "Payment processing cancelled by user"
          : res.message ?? 'Payment could not be processed',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.error,
      colorText: Colors.white,
    );
  }

  void startPayment(Map<String, dynamic> plan) {
    final amount = selectedDuration == 'yearly'
        ? (plan['yearly_price'] as num).toInt()
        : (plan['monthly_price'] as num).toInt();

    if (amount == 0) {
      // Free trial – activate directly
      controller.activatePlan(
        planName: plan['name'] as String,
        userLimit: plan['user_limit'] as int,
        duration: 'trial',
        amount: 0,
        paymentId: 'trial_${NetworkTime.now().millisecondsSinceEpoch}',
      );
      return;
    }

    setState(() => selectedPlan = plan);
    final options = {
      'key': 'rzp_test_SjGIA59xh9bikb', // Replace with actual Razorpay key
      'amount': amount * 100, // paise
      'name': 'Sri HR',
      'description':
          '${plan['name'].toString().toUpperCase()} Plan – ${selectedDuration.capitalizeFirst}',
      'prefill': {
        'email': Get.find<AuthController>().currentUser.value?.email ?? '',
        'contact': Get.find<AuthController>().currentUser.value?.phone ?? '',
      },
      'theme': {'color': '#3B5BDB'},
    };
    razorpay.open(options);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return AppShell(
      currentModule: 'subscription',
      title: 'Subscription',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isWide ? 24.0 : 10.0),
        child: Column(
          children: [
            CurrentPlanCard(),
            const SizedBox(height: 28),
            DurationToggle(
              selected: selectedDuration,
              onChanged: (v) => setState(() => selectedDuration = v),
            ),
            const SizedBox(height: 20),
            Obx(
              () => controller.isLoading.value
                  ? const LoadingOverlay()
                  : controller.plans.isEmpty
                  ? const EmptyState(
                      message: 'No plans available',
                      icon: Icons.card_membership_outlined,
                    )
                  : PlansGrid(
                      plans: controller.plans,
                      duration: selectedDuration,
                      onSelect: startPayment,
                    ),
            ),
            const SizedBox(height: 24),
            PaymentInfo(),
          ],
        ),
      ),
    );
  }
}
