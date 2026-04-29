import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircularProgressIndicator(color: AppColors.primary),
      SizedBox(height: 12),
      Text('Loading...',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
    ]));
  }
}
