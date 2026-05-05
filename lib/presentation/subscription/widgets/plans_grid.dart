import 'package:flutter/material.dart';
import 'package:sri_hr/presentation/subscription/widgets/plan_card.dart';

class PlansGrid extends StatelessWidget {
  final List<Map<String, dynamic>> plans;
  final String duration;
  final void Function(Map<String, dynamic>) onSelect;
  const PlansGrid({
    super.key,
    required this.plans,
    required this.duration,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final billablePlans = plans.where((p) => p['name'] != 'trial').toList();

    return isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: billablePlans
                .map(
                  (plan) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: PlanCard(
                        plan: plan,
                        duration: duration,
                        onSelect: onSelect,
                      ),
                    ),
                  ),
                )
                .toList(),
          )
        : Column(
            children: billablePlans
                .map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PlanCard(
                      plan: plan,
                      duration: duration,
                      onSelect: onSelect,
                    ),
                  ),
                )
                .toList(),
          );
  }
}
