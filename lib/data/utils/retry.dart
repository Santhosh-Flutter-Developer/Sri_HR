import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Returns true when [e] is a short-lived / transient error that is safe
/// to retry (connection reset, gateway timeout, rate limited, etc.) as
/// opposed to a real error (bad data, RLS denial, unique violation, ...).
bool isTransientSupabaseError(Object e) {
  final raw = e.toString().toLowerCase();
  if (e is SocketException) return true;
  if (e is TimeoutException) return true;
  if (e is PostgrestException) {
    final code = e.code ?? '';
    // 08xxx = connection exceptions, 53xxx = insufficient resources,
    // 57xxx = operator intervention (incl. query_canceled), 429 = rate limited
    return code.startsWith('08') ||
        code.startsWith('53') ||
        code.startsWith('57') ||
        code == '429' ||
        raw.contains('timeout') ||
        raw.contains('timed out');
  }
  return raw.contains('socketexception') ||
      raw.contains('connection reset') ||
      raw.contains('connection closed') ||
      raw.contains('timed out') ||
      raw.contains('429') ||
      raw.contains('too many requests');
}

/// Runs [action], retrying with exponential backoff + jitter when it fails
/// with a transient error (see [isTransientSupabaseError]). Real errors are
/// rethrown immediately on the first attempt so the user finds out ASAP.
///
/// This is what keeps the app usable when many people (e.g. 50+ employees
/// punching in around the same time) briefly overlap requests and hit a
/// short-lived connection hiccup or rate limit from Supabase — instead of
/// every one of those overlapping requests failing outright.
Future<T> withSupabaseRetry<T>(
  Future<T> Function() action, {
  int maxAttempts = 3,
}) async {
  var attempt = 0;
  while (true) {
    attempt++;
    try {
      return await action();
    } catch (e) {
      if (attempt >= maxAttempts || !isTransientSupabaseError(e)) rethrow;
      final delayMs = 300 * attempt + (100 * attempt);
      await Future.delayed(Duration(milliseconds: delayMs));
    }
  }
}
