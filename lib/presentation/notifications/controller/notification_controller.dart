import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/notification_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/leave/controller/leave_controller.dart';
import 'package:sri_hr/presentation/notifications/repository/notification_repository.dart';
import 'package:sri_hr/presentation/permission_request/controller/permission_request_controller.dart';
import 'package:sri_hr/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationController extends GetxController {
  final _repo = NotificationRepository();

  /// Unread notifications only (read ones are removed from this list).
  final items = <NotificationModel>[].obs;
  final isLoading = false.obs;

  RealtimeChannel? _channel;
  String? _listeningFor;

  int get unreadCount => items.length;

  String? get _uid {
    final fromAuth = SupabaseService.currentUserId;
    if (fromAuth != null && fromAuth.isNotEmpty) return fromAuth;
    final id = Get.find<AuthController>().userId;
    return id.isEmpty ? null : id;
  }

  // ── Lifecycle (called by AuthController on login / session restore) ──
  Future<void> start() async {
    final uid = _uid;
    if (uid == null) return;
    await load();
    _subscribe(uid);
  }

  void stop() {
    _channel?.unsubscribe();
    _channel = null;
    _listeningFor = null;
    items.clear();
  }

  Future<void> load() async {
    final uid = _uid;
    if (uid == null) return;
    isLoading.value = true;
    try {
      items.value = await _repo.getUnread(uid);
    } catch (e) {
      log('[NotifCtrl] load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Realtime: new notification → add to bell + in-app banner ──────────
  void _subscribe(String uid) {
    if (_listeningFor == uid && _channel != null) return;
    _channel?.unsubscribe();
    _listeningFor = uid;
    _channel = SupabaseService.client
        .channel('notifications_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: (payload) {
            final n = NotificationModel.fromJson(payload.newRecord);
            if (n.isRead || items.any((e) => e.id == n.id)) return;
            items.insert(0, n);
            _showBanner(n);
          },
        )
        .subscribe();
  }

  void _showBanner(NotificationModel n) {
    Get.snackbar(
      n.title,
      n.body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.sidebarBg,
      colorText: Colors.white,
      icon: const Icon(Icons.notifications_active_rounded, color: Colors.white),
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.all(12),
      onTap: (_) => open(n),
    );
  }

  // ── Read handling ──────────────────────────────────────────────────────
  Future<void> markRead(String id) async {
    final idx = items.indexWhere((e) => e.id == id);
    if (idx == -1) return; // already read / not in list
    final removed = items.removeAt(idx); // hide immediately
    try {
      await _repo.markRead(id);
    } catch (e) {
      log('[NotifCtrl] markRead error: $e');
      items.insert(idx.clamp(0, items.length), removed); // restore on failure
    }
  }

  Future<void> markAllRead() async {
    final uid = _uid;
    if (uid == null || items.isEmpty) return;
    final backup = List<NotificationModel>.from(items);
    items.clear();
    try {
      await _repo.markAllRead(uid);
    } catch (e) {
      log('[NotifCtrl] markAllRead error: $e');
      items.value = backup;
    }
  }

  /// Tap on a notification (list, in-app banner): mark read + redirect.
  Future<void> open(NotificationModel n) async {
    NotificationNavigator.open(n.type, n.status, notificationId: n.id);
  }
}

/// Central place that knows where each notification should lead.
class NotificationNavigator {
  static Map<String, dynamic>? _pending;

  /// Remember a tap that happened before the app/session was ready
  /// (e.g. app launched from a push while terminated).
  static void setPending(Map<String, dynamic> data) => _pending = data;

  /// Called once the dashboard is on screen.
  static void consumePending() {
    final d = _pending;
    _pending = null;
    if (d == null) return;
    open(
      d['type']?.toString(),
      d['status']?.toString(),
      notificationId: d['notification_id']?.toString(),
    );
  }

  /// Tap on a system push notification.
  static void handleTap(Map<String, dynamic> data) {
    final loggedIn =
        Get.isRegistered<AuthController>() &&
        Get.find<AuthController>().isLoggedIn;
    if (!loggedIn) {
      setPending(data);
      return;
    }
    open(
      data['type']?.toString(),
      data['status']?.toString(),
      notificationId: data['notification_id']?.toString(),
    );
  }

  static void open(String? type, String? status, {String? notificationId}) {
    if (notificationId != null &&
        notificationId.isNotEmpty &&
        Get.isRegistered<NotificationController>()) {
      Get.find<NotificationController>().markRead(notificationId);
    }

    final isPermission = type == 'permission';
    final route = isPermission ? AppRoutes.routePermission : AppRoutes.routeLeave;
    final filter = (status == null || status.isEmpty) ? 'pending' : status;

    // Already on that page → just apply the filter to the live controller.
    if (Get.currentRoute == route) {
      if (isPermission && Get.isRegistered<PermissionRequestController>()) {
        final c = Get.find<PermissionRequestController>();
        c.filterStatus.value = filter;
        c.load();
      } else if (!isPermission && Get.isRegistered<LeaveController>()) {
        final c = Get.find<LeaveController>();
        c.filterStatus.value = filter;
        c.loadLeaves();
      }
      return;
    }

    final args = {'status': filter};
    if (Get.currentRoute == AppRoutes.routeNotifications) {
      Get.offNamed(route, arguments: args); // replace list → back goes to dashboard
    } else {
      Get.toNamed(route, arguments: args);
    }
  }
}