import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showSuccess(String msg) => Get.snackbar(
  'Success', msg,
  snackPosition: SnackPosition.BOTTOM,
  backgroundColor: const Color(0xFF22C55E),
  colorText: Colors.white,
  duration: const Duration(seconds: 2),
  icon: const Icon(Icons.check_circle, color: Colors.white),
);

void showError(String msg,{String? title}) => Get.snackbar(
  title??'Error', msg,
  snackPosition: SnackPosition.BOTTOM,
  backgroundColor: const Color(0xFFEF4444),
  colorText: Colors.white,
  duration: const Duration(seconds: 3),
  icon: const Icon(Icons.error_outline, color: Colors.white),
);
