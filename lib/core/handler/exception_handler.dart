import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  NETWORK ERROR DETECTION
// ─────────────────────────────────────────────────────────────────────────────

/// Returns true when [e] is a connectivity / host-unreachable error.
bool isNetworkError(Object e) {
  if (e is SocketException) return true;
  final raw = e.toString();
  return raw.contains('SocketException') ||
      raw.contains('Failed host lookup') ||
      raw.contains('No address associated with hostname') ||
      raw.contains('ClientFailed to fetch') ||
      raw.contains('Failed to fetch') ||
      raw.contains('errno = 7') ||
      raw.contains('NetworkException') ||
      raw.contains('Connection refused') ||
      raw.contains('Connection timed out') ||
      raw.contains('Network is unreachable') ||
      raw.contains('OS Error');
}

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────

/// Converts any exception into a short, plain-English message a user can act on.
String handleException(Object e) {

  // ── 1. Network / connectivity ────────────────────────────────────────────
  if (isNetworkError(e)) {
    return 'No internet connection. Please check your Wi-Fi or mobile data and try again.';
  }

  // ── 2. Supabase auth errors ──────────────────────────────────────────────
  if (e is AuthException) return _authMessage(e.message);

  // ── 3. Supabase / PostgREST database errors ──────────────────────────────
  if (e is PostgrestException) return _postgrestMessage(e);

  final raw = e.toString();

  // ── 4. String-form Postgrest (wrapped exceptions) ─────────────────────────
  if (raw.contains('PostgrestException') || raw.contains('PostgREST')) {
    return _rawPostgrestMessage(raw);
  }

  // ── 5. File / storage permission (export PDF/Excel) ──────────────────────
  if (raw.contains('PathAccessException') ||
      raw.contains('Permission denied') ||
      raw.contains('errno = 13')) {
    return 'Storage permission denied.\n'
        'Go to Settings → Apps → Sri HR → Permissions → Files and enable it.';
  }

  // ── 6. Request timeout ───────────────────────────────────────────────────
  if (raw.contains('TimeoutException') || raw.contains('timed out')) {
    return 'The request took too long. Please check your internet and try again.';
  }

  // ── 7. Session / JWT expired ─────────────────────────────────────────────
  if (raw.contains('JWT') || raw.contains('token is expired') ||
      raw.contains('refresh_token_not_found')) {
    return 'Your session has expired. Please log in again.';
  }

  // ── 8. RPC / function not found ──────────────────────────────────────────
  if (raw.contains('function') && raw.contains('does not exist')) {
    return 'A required server function is missing. Please contact support.';
  }

  // ── 9. Known custom Exception messages (from repositories/controllers) ───
  if (raw.contains('Exception: ')) {
    final msg = raw.replaceFirst('Exception: ', '').trim();
    return _cleanCustomMessage(msg);
  }

  // ── 10. Fallback — strip noisy technical prefixes ─────────────────────────
  return raw
      .replaceAll('ClientException with SocketException: ', '')
      .replaceAll('ClientException: ', '')
      .replaceAll('ClientFailed to fetch, uri=', 'Unable to reach server. ')
      .replaceAll('FormatException: ', 'Invalid data format. ')
      .trim()
      .takeMax(120); // never dump a wall of text on the user
}

// ─────────────────────────────────────────────────────────────────────────────
//  AUTH EXCEPTION → human message
// ─────────────────────────────────────────────────────────────────────────────

String _authMessage(String msg) {
  final s = msg.toLowerCase();
  if (s.contains('invalid login credentials') || s.contains('invalid credentials') || s.contains('wrong password')) {
    return 'The email or password you entered is incorrect. Please try again.';
  }
  if (s.contains('email not confirmed')) {
    return 'Your email address has not been verified yet. Check your inbox for a confirmation link.';
  }
  if (s.contains('user not found') || s.contains('no user found')) {
    return 'No account found with this email address. Please check or sign up first.';
  }
  if (s.contains('email already') || s.contains('already registered')) {
    return 'This email is already registered. Please log in or use a different email.';
  }
  if (s.contains('too many requests') || s.contains('rate limit')) {
    return 'Too many login attempts. Please wait a few minutes and try again.';
  }
  if (s.contains('token') && s.contains('expire')) {
    return 'Your session has expired. Please log in again.';
  }
  if (s.contains('weak password')) {
    return 'Password is too weak. Use at least 8 characters with letters, numbers, and symbols.';
  }
  if (s.contains('signup') && s.contains('disabled')) {
    return 'New registrations are currently disabled. Please contact support.';
  }
  if (s.contains('phone') && s.contains('invalid')) {
    return 'The phone number format is invalid. Please enter a valid number.';
  }
  return msg.isNotEmpty ? msg : 'Authentication failed. Please try again.';
}

// ─────────────────────────────────────────────────────────────────────────────
//  POSTGREST EXCEPTION → human message
// ─────────────────────────────────────────────────────────────────────────────

String _postgrestMessage(PostgrestException e) {
  final code   = e.code ?? '';
  final msg    = e.message.toLowerCase();
  final detail = (e.details ?? '').toString().toLowerCase();
  final hint   = (e.hint   ?? '').toString().toLowerCase();
  final all    = '$msg $detail $hint';

  // ── Unique constraint (duplicate value) ───────────────────────────────────
  if (code == '23505') return _duplicateMessage(all);

  // ── Foreign key violation ─────────────────────────────────────────────────
  if (code == '23503') {
    if (all.contains('department')) {
      return 'This department is still assigned to one or more employees. Remove or reassign those employees first.';
    }
    if (all.contains('role') || all.contains('designation')) {
      return 'This designation/role is still assigned to employees. Reassign them before deleting.';
    }
    if (all.contains('employee')) {
      return 'This employee has linked records. Remove related data first.';
    }
    if (all.contains('company')) {
      return 'This branch has linked records and cannot be removed directly.';
    }
    return 'This record is linked to other data and cannot be deleted. Remove the related records first.';
  }

  // ── Not-null / missing required field ────────────────────────────────────
  if (code == '23502') {
    final col = _extractColumn(detail);
    return col != null
        ? 'The "$col" field is required. Please fill it in before saving.'
        : 'A required field is missing. Please fill in all required fields.';
  }

  // ── Check constraint failed ───────────────────────────────────────────────
  if (code == '23514') {
    if (all.contains('date') || all.contains('from') && all.contains('to')) {
      return 'The date range is invalid. Please check that the start date is before the end date.';
    }
    return 'One or more values are outside the allowed range. Please check your inputs.';
  }

  // ── Row-level security / permission denied ────────────────────────────────
  if (code == '42501' || code == 'PGRST301') {
    return 'You do not have permission to perform this action. Contact your administrator.';
  }

  // ── JWT / session errors from PostgREST ──────────────────────────────────
  if (code == 'PGRST302') {
    return 'Your session has expired. Please log in again.';
  }

  // ── No rows returned when one was expected ───────────────────────────────
  if (code == 'PGRST116') {
    return 'The requested record was not found. It may have been deleted.';
  }

  // ── RPC error with a message ──────────────────────────────────────────────
  if (e.message.isNotEmpty) {
    // Surface clean RPC error messages (set via RAISE EXCEPTION in SQL)
    final cleaned = e.message
        .replaceAll('ERROR: ', '')
        .replaceAll('DETAIL: ', '')
        .trim();
    if (cleaned.length < 200) return cleaned;
  }

  return 'An unexpected database error occurred. Please try again or contact support.';
}

// ─────────────────────────────────────────────────────────────────────────────
//  DUPLICATE KEY → field-specific message
// ─────────────────────────────────────────────────────────────────────────────

String _duplicateMessage(String ctx) {
  if (ctx.contains('gstin')) {
    return 'This GSTIN is already registered in the system. Each company must have a unique GSTIN.';
  }
  if (ctx.contains('email')) {
    return 'This email address is already in use by another account. Please use a different email.';
  }
  if (ctx.contains('phone') || ctx.contains('mobile')) {
    return 'This phone number is already registered. Please use a different number.';
  }
  if (ctx.contains('branch_code') || ctx.contains('branchcode')) {
    return 'This branch code is already taken. Please choose a different code.';
  }
  if (ctx.contains('employee_code') || ctx.contains('employeecode')) {
    return 'This employee code is already assigned to someone else. Please use a different code.';
  }
  if (ctx.contains('username')) {
    return 'This username is already taken. Please choose a different username.';
  }
  if (ctx.contains('name')) {
    return 'A record with this name already exists. Please use a different name.';
  }
  if (ctx.contains('kiosk')) {
    return 'This kiosk username is already in use. Please choose a different one.';
  }
  return 'A record with this value already exists. Please use a unique value.';
}

// ─────────────────────────────────────────────────────────────────────────────
//  RAW STRING POSTGREST (wrapped in outer exception toString)
// ─────────────────────────────────────────────────────────────────────────────

String _rawPostgrestMessage(String raw) {
  if (raw.contains('23505') || raw.contains('duplicate key')) {
    return _duplicateMessage(raw.toLowerCase());
  }
  if (raw.contains('23503')) {
    return 'This record is linked to other data and cannot be deleted. Remove related records first.';
  }
  if (raw.contains('23502')) {
    return 'A required field is missing. Please fill in all required fields.';
  }
  if (raw.contains('42501') || raw.contains('insufficient_privilege')) {
    return 'You do not have permission to perform this action.';
  }
  if (raw.contains('PGRST116')) {
    return 'The requested record was not found.';
  }
  return 'An unexpected database error occurred. Please try again.';
}

// ─────────────────────────────────────────────────────────────────────────────
//  CUSTOM EXCEPTION MESSAGES (thrown manually in controllers/repos)
// ─────────────────────────────────────────────────────────────────────────────

String _cleanCustomMessage(String msg) {
  // These are already user-friendly — just clean up technical noise
  final clean = msg
      .replaceAll('Exception: ', '')
      .replaceAll('FormatException: ', '')
      .trim();

  // Map any remaining technical phrases to plain English
  final lower = clean.toLowerCase();

  if (lower.contains('organization not found')) {
    return 'Your organisation record could not be found. Please contact support.';
  }
  if (lower.contains('failed to preview employee code') ||
      lower.contains('failed to generate employee code')) {
    return 'Could not generate an employee code. Please try again or enter one manually.';
  }
  if (lower.contains('invalid credentials')) {
    return 'The email or password is incorrect. Please try again.';
  }
  if (lower.contains('user profile not found')) {
    return 'Your user profile is missing. Please contact your administrator.';
  }
  if (lower.contains('could not create account')) {
    return 'Account creation failed. This email may already be registered.';
  }
  if (lower.contains('already registered as a different account')) {
    return 'This email belongs to an existing account. Please use a different email for this employee.';
  }

  // Message is already plain-English — return as-is
  return clean;
}

// ─────────────────────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Try to extract the column name from a NOT NULL detail string like
/// "null value in column \"full_name\" ..."
String? _extractColumn(String detail) {
  final match = RegExp(r'column "([^"]+)"').firstMatch(detail);
  if (match == null) return null;
  return match.group(1)!
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

extension _StringExt on String {
  String takeMax(int max) => length <= max ? this : '${substring(0, max)}…';
}