import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/subscription/widgets/pay_icon.dart';

class PaymentInfo extends StatelessWidget {
  const PaymentInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        const Row(children: [
          Icon(Icons.security_rounded, size: 16, color: AppColors.textMuted),
          SizedBox(width: 8),
          Text('Secure Payment via Razorpay',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 8),
        const Text(
            'All payments are encrypted and processed securely. Supports UPI, Net Banking, Cards & Wallets.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          PayIcon('UPI'),
          const SizedBox(width: 8),
          PayIcon('Cards'),
          const SizedBox(width: 8),
          PayIcon('Net Banking'),
        ]),
      ]),
    );
  }
}
