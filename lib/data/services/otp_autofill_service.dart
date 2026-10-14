import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:smart_auth/smart_auth.dart';

/// Auto-fetches the OTP from the incoming SMS on Android using the
/// SMS User Consent API (no app-hash needed, works with the fixed DLT
/// template). On iOS the keyboard suggestion (AutofillHints.oneTimeCode)
/// is used; on web this does nothing.
class OtpAutofillService {
  OtpAutofillService._();

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Starts listening for an SMS. When a [length]-digit code is found it is
  /// written into [controller] and [onFilled] is called.
  static Future<void> listen(
    TextEditingController controller, {
    int length = 6,
    VoidCallback? onFilled,
  }) async {
    if (!_supported) return;
    try {
      // Stop any previous listener first (e.g. on resend).
      await stop();

      final res = await SmartAuth.instance.getSmsWithUserConsentApi();
      if (!res.hasData) return; // user denied / timed out

      final sms = res.data?.sms ?? '';
      final match = RegExp('(?<!\\d)(\\d{$length})(?!\\d)').firstMatch(sms);
      final code = match?.group(1);
      if (code == null) return;

      controller.text = code;
      controller.selection = TextSelection.collapsed(offset: code.length);
      onFilled?.call();
    } catch (e) {
      log('OtpAutofillService error: $e');
    }
  }

  static Future<void> stop() async {
    if (!_supported) return;
    try {
      await SmartAuth.instance.removeUserConsentApiListener();
    } catch (_) {}
  }
}