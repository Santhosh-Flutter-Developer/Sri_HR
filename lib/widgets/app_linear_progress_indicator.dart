import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class AppLinearProgressIndicator extends StatelessWidget {
  final double? width;
  final Color? color;
  const AppLinearProgressIndicator({super.key, this.width, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8 * 2),
        child: LinearProgressIndicator(
          color: color ?? AppColors.primary,
          backgroundColor: color != null
              ? color?.withOpacity(.5)
              : AppColors.primary.withOpacity(.5),
        ),
      ),
    );
  }
}
