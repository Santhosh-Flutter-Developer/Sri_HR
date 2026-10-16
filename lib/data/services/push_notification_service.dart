import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:sri_hr/presentation/notifications/controller/notification_controller.dart';

/// Runs in its own isolate when a push arrives while the app is in the
/// background / terminated. The OS already shows the notification (the FCM
/// message carries a `notification` block), so nothing else is needed here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// FCM push (Android / iOS only). On web / desktop this is a no-op – the
/// in-app bell + realtime still work there.
class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();

  bool _ready = false;
  String? _token;
  StreamSubscription<String>? _refreshSub;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Call once from main() before runApp().
  Future<void> init() async {
    if (!_supported) return;
    try {
      await Firebase.initializeApp(); // needs google-services.json / plist
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _ready = true;

      // App in background → user taps the notification
      FirebaseMessaging.onMessageOpenedApp.listen(
        (m) => NotificationNavigator.handleTap(m.data),
      );

      // App terminated → launched by tapping the notification
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) NotificationNavigator.setPending(initial.data);
    } catch (e) {
      // Firebase not configured yet → push disabled, app still works.
      log('[Push] init skipped: $e');
    }
  }

  /// Ask permission, fetch the FCM token and store it for the current user.
  /// Do NOT await this in the login flow (it may show a permission dialog).
  Future<void> registerToken() async {
    if (!_ready) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      // iOS: FCM needs the APNs token first; it can arrive a moment late.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apns;
        for (var i = 0; i < 10 && apns == null; i++) {
          apns = await FirebaseMessaging.instance.getAPNSToken();
          if (apns == null) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
        if (apns == null) {
          log('[Push] APNs token not available (simulator, or Push '
              'capability / APNs key missing)');
          return;
        }
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _save(token);

      _refreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen(_save);
    } catch (e) {
      log('[Push] registerToken error: $e');
    }
  }

  Future<void> _save(String token) async {
    _token = token;
    if (!SupabaseService.isLoggedIn) return;
    try {
      await SupabaseService.client.rpc(
        'register_device_token',
        params: {
          'p_token': token,
          'p_platform': defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
        },
      );
    } catch (e) {
      log('[Push] save token error: $e');
    }
  }

  /// Call on logout (BEFORE signing out) so this phone stops receiving the
  /// previous user's notifications.
  Future<void> unregisterToken() async {
    if (!_ready || _token == null) return;
    try {
      await SupabaseService.client
          .from('device_tokens')
          .delete()
          .eq('token', _token!);
    } catch (e) {
      log('[Push] unregister error: $e');
    }
  }
}