import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({
    super.key,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 15, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
