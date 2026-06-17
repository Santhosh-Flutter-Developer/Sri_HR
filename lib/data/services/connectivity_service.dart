import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Monitors internet connectivity globally.
///
/// Key behaviours:
///  1. Shows a persistent offline banner — NO individual page error toasts.
///  2. When internet restores, auto-retries every registered load function
///     and shows a single "Connected" toast.
///  3. Controllers register their reload fn via [register]; the service
///     calls them all when connection comes back.
///  4. [suppressOfflineErrors] is true while offline — used by
///     showError() in helper.dart to silently drop network-error toasts.
class ConnectivityService extends GetxService {
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  final isConnected = true.obs;

  /// True while the device is offline — helpers read this to suppress
  /// redundant per-page error toasts.
  bool get suppressOfflineErrors => !isConnected.value;

  // ── Registered reload callbacks ─────────────────────────────────────────
  final List<Future<void> Function()> _reloadCallbacks = [];

  /// Controllers call this in their onInit to register their load function
  /// for auto-retry when connectivity restores.
  void register(Future<void> Function() loader) {
    if (!_reloadCallbacks.contains(loader)) {
      _reloadCallbacks.add(loader);
    }
  }

  void unregister(Future<void> Function() loader) {
    _reloadCallbacks.remove(loader);
  }

  @override
  void onInit() {
    super.onInit();
    _checkInitial();
    _sub = _connectivity.onConnectivityChanged.listen(_onChanged);
  }

  @override
  void onClose() {
    _sub?.cancel();
    _reloadCallbacks.clear();
    super.onClose();
  }

  // ── Initial check ────────────────────────────────────────────────────────

  Future<void> _checkInitial() async {
    final results = await _connectivity.checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);
    isConnected.value = online;
    if (!online) _showOfflineBar();
  }

  // ── React to connectivity changes ────────────────────────────────────────

  void _onChanged(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online == isConnected.value) return;

    isConnected.value = online;

    // Always close whatever is currently showing
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

    if (!online) {
      _showOfflineBar();
    } else {
      _onRestored();
    }
  }

  // ── Internet restored ────────────────────────────────────────────────────

  void _onRestored() {
    _showOnlineBar();
    // Small delay so the toast renders before data fetches start
    Future.delayed(const Duration(milliseconds: 800), _retryAll);
  }

  Future<void> _retryAll() async {
    if (!isConnected.value) return;
    // Fire all registered loaders concurrently; ignore individual errors
    await Future.wait(
      _reloadCallbacks.map((fn) => fn().catchError((_) {})),
    );
  }

  // ── Manual retry (Retry button in offline banner) ───────────────────────

  Future<void> retryNow() async {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    final results = await _connectivity.checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);
    isConnected.value = online;
    if (online) {
      _onRestored();
    } else {
      _showOfflineBar(); // re-show banner
    }
  }

  // ── Offline banner (persistent, no auto-dismiss) ─────────────────────────

  void _showOfflineBar() {
    Get.snackbar(
      'No Internet',
      'You are offline. Data will refresh when connection is restored.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF1E293B),
      colorText: Colors.white,
      icon: const Icon(Icons.wifi_off_rounded, color: Colors.white),
      duration: const Duration(days: 1),
      isDismissible: false,
      margin: const EdgeInsets.all(0),
      borderRadius: 0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      mainButton: TextButton(
        onPressed: retryNow,
        child: const Text(
          'Retry',
          style: TextStyle(
            color: Color(0xFF60A5FA),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── Back-online banner (auto-dismiss) ────────────────────────────────────

  void _showOnlineBar() {
    Get.snackbar(
      'Connected',
      'Back online — refreshing data…',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF22C55E),
      colorText: Colors.white,
      icon: const Icon(Icons.wifi_rounded, color: Colors.white),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(0),
      borderRadius: 0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ── Static helpers used across the app ──────────────────────────────────

  /// True when offline — controllers/helpers read this.
  static bool get offline {
    try {
      return !Get.find<ConnectivityService>().isConnected.value;
    } catch (_) {
      return false;
    }
  }

  /// True when connected.
  static bool get online => !offline;
}