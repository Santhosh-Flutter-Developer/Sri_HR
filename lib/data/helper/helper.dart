import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/data/services/connectivity_service.dart';

// ── Dedup guard: tracks the last error message shown ─────────────────────
String? _lastErrorMsg;
DateTime? _lastErrorTime;

/// Shows an error toast — but silently drops it when:
///   • The device is offline (connectivity banner already covers this), OR
///   • The exact same message was shown within the last 3 seconds (dedup).
void showError(String msg, {String? title}) {
  // 1. Suppress all per-page errors while offline — the banner is enough
  if (ConnectivityService.offline) return;

  // 2. Also suppress if this message looks like a network error
  //    (catches cases where online flag hasn't updated yet)
  if (_looksLikeNetworkError(msg)) return;

  // 3. Deduplicate — same message within 3 s = skip
  final now = DateTime.now();
  if (_lastErrorMsg == msg &&
      _lastErrorTime != null &&
      now.difference(_lastErrorTime!).inSeconds < 3) {
    return;
  }
  _lastErrorMsg  = msg;
  _lastErrorTime = now;

  if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

  Get.snackbar(
    title ?? 'Error',
    msg,
    snackPosition: SnackPosition.TOP,
    backgroundColor: const Color(0xFFEF4444),
    colorText: Colors.white,
    duration: const Duration(seconds: 4),
    icon: const Icon(Icons.error_outline, color: Colors.white),
    margin: const EdgeInsets.all(0),
    borderRadius: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

void showSuccess(String msg) {
  if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
  Get.snackbar(
    'Success',
    msg,
    snackPosition: SnackPosition.TOP,
    backgroundColor: const Color(0xFF22C55E),
    colorText: Colors.white,
    duration: const Duration(seconds: 2),
    icon: const Icon(Icons.check_circle, color: Colors.white),
    margin: const EdgeInsets.all(0),
    borderRadius: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

void showWarning(String msg, {String? title}) {
  if (ConnectivityService.offline) return;
  if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
  Get.snackbar(
    title ?? 'Warning',
    msg,
    snackPosition: SnackPosition.TOP,
    backgroundColor: const Color(0xFFF59E0B),
    colorText: Colors.white,
    duration: const Duration(seconds: 3),
    icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
    margin: const EdgeInsets.all(0),
    borderRadius: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

void showNoInternet() {
  if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
  Get.snackbar(
    'No Internet',
    'Please check your connection and try again.',
    snackPosition: SnackPosition.TOP,
    backgroundColor: const Color(0xFF1E293B),
    colorText: Colors.white,
    duration: const Duration(seconds: 3),
    icon: const Icon(Icons.wifi_off_rounded, color: Colors.white),
    margin: const EdgeInsets.all(0),
    borderRadius: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

bool _looksLikeNetworkError(String msg) {
  final lower = msg.toLowerCase();
  return lower.contains('no internet') ||
      lower.contains('failed host lookup') ||
      lower.contains('socketexception') ||
      lower.contains('failed to fetch') ||
      lower.contains('clientfailed') ||
      lower.contains('connection refused') ||
      lower.contains('network') && lower.contains('error');
}