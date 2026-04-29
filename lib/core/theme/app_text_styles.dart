import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';

class AppTextStyles {
  static const h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    fontFamily: 'Nunito',
  );
  static const h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFamily: 'Nunito',
  );
  static const h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFamily: 'Nunito',
  );
  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    fontFamily: 'Nunito',
  );
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    fontFamily: 'Nunito',
  );
}
