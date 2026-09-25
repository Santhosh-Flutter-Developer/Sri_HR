import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sri_hr/data/utils/retry.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;

  static User? get currentUser => auth.currentUser;
  static String? get currentUserId => currentUser?.id;
  static bool get isLoggedIn => currentUser != null;

  // ── Auth ──────────────────────────────────
  static Future<AuthResponse> signInWithEmail(String email, String password) =>
      auth.signInWithPassword(email: email, password: password);

  static Future<AuthResponse> signUpWithEmail(String email, String password) =>
      auth.signUp(email: email, password: password);

  static Future<void> signOut() => auth.signOut();

  static Stream<AuthState> get authStateChanges => auth.onAuthStateChange;

  static Future<T> _withRetry<T>(Future<T> Function() action) =>
      withSupabaseRetry(action);

  // ── Generic CRUD ──────────────────────────
  static Future<List<Map<String, dynamic>>> select(
    String table, {
    String? columns,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    return _withRetry(() async {
      dynamic query = client.from(table).select(columns ?? '*');
      query = _applyFilters(query, filters);
      query = query.order(orderBy ?? 'created_at', ascending: ascending);
      if (limit != null) {
        query = query.limit(limit);
      }
      final result = await query;
      return (result as List).cast<Map<String, dynamic>>();
    });
  }

  static dynamic _applyFilters(dynamic query, Map<String, dynamic>? filters) {
    if (filters == null) return query;
    filters.forEach((key, value) {
      query = query.eq(key, value);
    });
    return query;
  }

  /// Inserts a row. Throws on failure (does NOT silently swallow errors) —
  /// callers must handle the exception (e.g. via handleException) so the
  /// user actually finds out the save failed, instead of the UI silently
  /// behaving as if it succeeded while an empty map flows downstream.
  ///
  /// Deliberately NOT auto-retried: if the request actually reached the
  /// server and succeeded but the client only saw a timeout, retrying
  /// would silently create a duplicate row (e.g. a duplicate attendance
  /// punch or a duplicate department). Reads/updates/deletes are safe to
  /// retry because they're idempotent; a plain insert is not.
  static Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      return await client.from(table).insert(data).select().single();
    } catch (e) {
      log('SupabaseService.insert[$table] ERROR: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> update(
    String table,
    String id,
    Map<String, dynamic> data,
  ) {
    return _withRetry(() async {
      return await client
          .from(table)
          .update(data)
          .eq('id', id)
          .select()
          .single();
    });
  }

  static Future<void> delete(String table, String id) {
    return _withRetry(() async {
      await client.from(table).delete().eq('id', id);
    });
  }

  static Future<Map<String, dynamic>?> selectOne(
    String table, {
    String? columns,
    required String id,
  }) {
    return _withRetry(() async {
      return await client
          .from(table)
          .select(columns ?? '*')
          .eq('id', id)
          .maybeSingle();
    });
  }

  // ── Storage ───────────────────────────────
  static Future<String> uploadFile(
    String bucket,
    String path,
    dynamic file, {
    String? contentType,
  }) {
    return _withRetry(() async {
      await client.storage
          .from(bucket)
          .uploadBinary(
            path,
            file,
            fileOptions: FileOptions(
              contentType: contentType ?? 'image/jpeg',
              upsert: true,
            ),
          );
      return client.storage.from(bucket).getPublicUrl(path);
    });
  }

  static Future<void> deleteFile(String bucket, String path) {
    return _withRetry(() async {
      await client.storage.from(bucket).remove([path]);
    });
  }

  // ── RPC / Functions ───────────────────────
  // Not auto-retried: this is a generic passthrough used for both read-only
  // RPCs (get_email_by_username, etc.) and write RPCs (register_company,
  // set_kiosk_credentials, etc.). Retrying a write RPC after a client-side
  // timeout could re-run it and duplicate data server-side, so we leave
  // retry decisions to the caller for this one.
  static Future<dynamic> rpc(String fn, {Map<String, dynamic>? params}) {
    return client.rpc(fn, params: params);
  }
}
