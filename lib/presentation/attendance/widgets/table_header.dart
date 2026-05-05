import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class TableHeader extends StatelessWidget {
  const TableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: TH('Employee')),
          Expanded(flex: 2, child: TH('Date')),
          Expanded(flex: 2, child: TH('IN Time')),
          Expanded(flex: 2, child: TH('OUT Time')),
          Expanded(flex: 2, child: TH('Total Hrs')),
          SizedBox(width: 60, child: TH('Action', center: true)),
        ],
      ),
    );
  }
}

class TH extends StatelessWidget {
  final String text;
  final bool center;
  const TH(this.text, {super.key, this.center = false});
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: 12,
      letterSpacing: 0.3,
    ),
    textAlign: center ? TextAlign.center : TextAlign.left,
  );
}
