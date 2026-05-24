import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';

class PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final String duration;
  final void Function(Map<String, dynamic>) onSelect;
  const PlanCard({
    super.key,
    required this.plan,
    required this.duration,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    final name = plan['name'] as String;
    final isPro = name == 'pro';
    final price = duration == 'yearly'
        ? plan['yearly_price']
        : plan['monthly_price'];
    final features = _features(name);
    final auth = Get.find<AuthController>();
    final isCurrentPlan = auth.subscription.value?.plan.name == name;

    return Container(
      decoration: BoxDecoration(
        color: isPro ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPro ? AppColors.primary : AppColors.border,
          width: isPro ? 0 : 1,
        ),
        boxShadow: isPro
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPro)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            if (!isPro) const SizedBox(height: 22),
            const SizedBox(height: 12),
            Text(
              name.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: isPro
                    ? Colors.white.withOpacity(0.8)
                    : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹$price',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Nunito',
                    color: isPro ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '/${duration == 'yearly' ? 'yr' : 'mo'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isPro
                        ? Colors.white.withOpacity(0.7)
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
            Text(
              'Up to ${plan['user_limit']} users',
              style: TextStyle(
                fontSize: 13,
                color: isPro
                    ? Colors.white.withOpacity(0.8)
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: isPro ? Colors.greenAccent : AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      f,
                      style: TextStyle(
                        fontSize: 13,
                        color: isPro ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (auth.canAdd("subscription") || auth.canEdit("subscription"))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isCurrentPlan ? null : () => onSelect(plan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPro ? Colors.white : AppColors.primary,
                    foregroundColor: isPro ? AppColors.primary : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: isPro
                        ? Colors.white.withOpacity(0.3)
                        : AppColors.border,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: isWide ? 8.0 : 0.0),
                    child: Text(
                      isCurrentPlan ? 'Current Plan' : 'Get Started',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<String> _features(String plan) => switch (plan) {
    'basic' => [
      'All HR modules',
      'Up to 10 users',
      '5GB storage',
      'Email support',
    ],
    'pro' => [
      'All HR modules',
      'Up to 50 users',
      '20GB storage',
      'API access',
      'Priority support',
    ],
    'premium' => [
      'All HR modules',
      'Unlimited users',
      'Unlimited storage',
      'API access',
      'Custom branding',
      '24/7 support',
    ],
    _ => [],
  };
}
