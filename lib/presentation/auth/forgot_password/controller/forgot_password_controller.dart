import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/handler/exception_handler.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/services/sms_service.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:sri_hr/data/utils/otp_generator.dart';
import 'package:sri_hr/routes/app_routes.dart';

/// Steps: 0 = identifier, 1 = OTP, 2 = new password
class ForgotPasswordController extends GetxController {
  // ── Form keys ────────────────────────────────────────────
  final identifierFormKey = GlobalKey<FormState>();
  final otpFormKey        = GlobalKey<FormState>();
  final passwordFormKey   = GlobalKey<FormState>();

  // ── Text controllers ─────────────────────────────────────
  final identifierCtrl      = TextEditingController();
  final otpCtrl             = TextEditingController();
  final newPasswordCtrl     = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  // ── Observables ──────────────────────────────────────────
  RxInt    step            = 0.obs;
  RxBool   isLoading       = false.obs;
  RxBool   showNewPass     = false.obs;
  RxBool   showConfirmPass = false.obs;
  RxBool   otpSent         = false.obs;
  RxBool   otpVerified     = false.obs;
  RxString maskedPhone     = ''.obs;

  // ── Internal state ────────────────────────────────────────
  String _resolvedEmail  = '';
  String _resolvedUserId = '';
  String _resolvedPhone  = '';   // full phone kept for resend
  String _activeOtp      = '';
  Timer? _resendTimer;
  RxInt  resendSeconds = 0.obs;
  RxBool canResend     = true.obs;

  @override
  void onClose() {
    _resendTimer?.cancel();
    identifierCtrl.dispose();
    otpCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────
  // STEP 0 — Lookup user by email or username
  // ─────────────────────────────────────────────────────────
  Future<void> lookupUser() async {
    if (!identifierFormKey.currentState!.validate()) return;

    final input = identifierCtrl.text.trim();
    isLoading.value = true;

    try {
      dynamic rows;

      if (input.contains('@')) {
        rows = await SupabaseService.client.rpc(
          'get_user_phone_by_email',
          params: {'p_email': input.toLowerCase()},
        );
      } else {
        rows = await SupabaseService.client.rpc(
          'get_user_phone_by_username',
          params: {'p_username': input},
        );
      }

      log('[ForgotPw] RPC result: $rows  (type: ${rows.runtimeType})');

      // ── Parse response ────────────────────────────────────
      Map<String, dynamic>? data;

      if (rows == null) {
        _showError(
          input.contains('@')
              ? 'No account found with that email.'
              : 'No account found with that username.',
        );
        return;
      }

      if (rows is Map) {
        data = Map<String, dynamic>.from(rows);
      } else if (rows is List && rows.isNotEmpty && rows.first is Map) {
        // Some Supabase versions return a list
        data = Map<String, dynamic>.from(rows.first as Map);
      } else {
        log('[ForgotPw] Unexpected RPC shape: $rows');
        _showError('Received an unexpected response from the server. Please try again.');
        return;
      }

      final email  = data['email']   as String?;
      final userId = data['user_id'] as String?;
      final phone  = data['phone']   as String?;

      log('[ForgotPw] email=$email  userId=$userId  phone=$phone');

      if (email == null || userId == null) {
        _showError(
          input.contains('@')
              ? 'No account found with that email.'
              : 'No account found with that username.',
        );
        return;
      }

      if (phone == null || phone.trim().isEmpty) {
        _showError(
          'No mobile number linked to this account.\n'
          'Please contact your administrator.',
        );
        return;
      }

      _resolvedEmail  = email;
      _resolvedUserId = userId;
      _resolvedPhone  = phone.trim();

      // Mask phone → ******7890
      final clean = _resolvedPhone.replaceAll(RegExp(r'\D'), '');
      final last4 = clean.length >= 4 ? clean.substring(clean.length - 4) : clean;
      maskedPhone.value = '******$last4';

      await _sendOtp(_resolvedPhone);
    } catch (e, st) {
      log('[ForgotPw] lookupUser error: $e\n$st');
      // Surface a helpful message for common Supabase errors
      final msg = e.toString();
      if (msg.contains('function') && msg.contains('does not exist')) {
        _showError(
          'Server function not found.\n'
          'Please run the SQL setup script in your Supabase dashboard.',
        );
      } else {
        _showError(handleException(e));
      }
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // Send OTP (internal)
  // ─────────────────────────────────────────────────────────
  Future<void> _sendOtp(String phone) async {
    // Normalise: strip non-digits, strip 91 prefix → keep 10 digits
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }
    if (digits.length != 10) {
      log('[ForgotPw] Bad phone digits length ${digits.length} for "$phone"');
      _showError(
        'The mobile number on record is invalid ($phone).\n'
        'Please contact your administrator.',
      );
      return;
    }

    _activeOtp = OtpGenerator.generate();
    log('[ForgotPw] Sending OTP $_activeOtp to 91$digits');

    final sent = await SmsService.sendOtp(
      mobileNumber: '91$digits',
      otp: _activeOtp,
      appName: 'Srisoft',
    );

    if (sent) {
      otpSent.value = true;
      step.value = 1;
      _startResendTimer();
      _showSuccess('OTP sent to $maskedPhone');
    } else {
      _showError(
        'Failed to send OTP to $maskedPhone.\n'
        'Check SMS service credentials or try again.',
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  // Resend OTP (public — called from UI)
  // ─────────────────────────────────────────────────────────
  Future<void> resendOtp() async {
    if (!canResend.value) return;
    isLoading.value = true;
    try {
      otpCtrl.clear();
      await _sendOtp(_resolvedPhone);
    } catch (e) {
      _showError('Could not resend the OTP. Please check your internet connection and try again.');
    } finally {
      isLoading.value = false;
    }
  }

  void _startResendTimer() {
    canResend.value      = false;
    resendSeconds.value  = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendSeconds.value <= 1) {
        t.cancel();
        canResend.value = true;
        resendSeconds.value = 0;
      } else {
        resendSeconds.value--;
      }
    });
  }

  // ─────────────────────────────────────────────────────────
  // STEP 1 — Verify OTP
  // ─────────────────────────────────────────────────────────
  void verifyOtp() {
    if (!otpFormKey.currentState!.validate()) return;

    final entered = otpCtrl.text.trim();
    if (entered == _activeOtp) {
      _resendTimer?.cancel();
      otpVerified.value = true;
      step.value = 2;
      _showSuccess('OTP verified! Set your new password.');
    } else {
      otpCtrl.clear();
      _showError('The OTP you entered is incorrect. Please check and try again.');
    }
  }

  // ─────────────────────────────────────────────────────────
  // STEP 2 — Update password
  // ─────────────────────────────────────────────────────────
  Future<void> updatePassword() async {
    if (!passwordFormKey.currentState!.validate()) return;
    if (!otpVerified.value) {
      _showError('OTP verification is incomplete. Please go back and verify your mobile number again.');
      return;
    }

    isLoading.value = true;
    try {
      await SupabaseService.client.rpc(
        'reset_user_password',
        params: {
          'p_user_id':      _resolvedUserId,
          'p_new_password': newPasswordCtrl.text.trim(),
        },
      );

      _showSuccess('Password updated successfully! Please sign in.');
      await Future.delayed(const Duration(milliseconds: 1200));
      Get.offAllNamed(AppRoutes.routeLogin);
    } catch (e) {
      log('[ForgotPw] updatePassword error: $e');
      _showError(handleException(e));
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // Validators
  // ─────────────────────────────────────────────────────────
  String? validateIdentifier(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Please enter your email or username';
    }
    if (v.contains('@')) {
      final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
      if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
    }
    return null;
  }

  String? validateOtp(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter the 6-digit OTP';
    if (v.trim().length != 6) return 'OTP must be 6 digits';
    return null;
  }

  String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password cannot be empty';
    if (v.length < 8) return 'Must be at least 8 characters';
    if (!v.contains(RegExp(r'[A-Z]'))) return 'Must contain an uppercase letter';
    if (!v.contains(RegExp(r'[a-z]'))) return 'Must contain a lowercase letter';
    if (!v.contains(RegExp(r'[0-9]'))) return 'Must contain a number';
    if (!v.contains(RegExp(r'[^A-Za-z0-9\s]'))) return 'Must contain a special character';
    if (v.contains(RegExp(r'\s'))) return 'Must not contain spaces';
    return null;
  }

  String? validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != newPasswordCtrl.text) return 'Passwords do not match';
    return null;
  }

  // ─────────────────────────────────────────────────────────
  // Navigation
  // ─────────────────────────────────────────────────────────
  void goBack() {
    if (step.value == 1) {
      step.value = 0;
      otpCtrl.clear();
      otpSent.value = false;
      _resendTimer?.cancel();
    } else {
      Get.back();
    }
  }

  // ─────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────
  String trimError(String e) {
    // Strip long Supabase stack traces for user-facing messages
    final idx = e.indexOf('\n');
    return idx > 0 ? e.substring(0, idx) : e;
  }

  void _showError(String msg) {
    Get.snackbar(
      'Error',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.error,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 4),
    );
  }

  void _showSuccess(String msg) {
    Get.snackbar(
      'Success',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
    );
  }
}