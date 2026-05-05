import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;
  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: steps.asMap().entries.map((e) {
        final idx = e.key;
        final label = e.value;
        final isDone = idx < currentStep;
        final isCurrent = idx == currentStep;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Container(
                  width: 32.0,
                  height: 32.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppColors.success
                        : isCurrent
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '${idx + 1}',
                            style: TextStyle(
                              color: isCurrent
                                  ? Colors.white
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                    color: isCurrent ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
            if (idx < steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  height: 2,
                  width: 100.0,

                  color: idx < currentStep
                      ? AppColors.success
                      : AppColors.border,
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}
