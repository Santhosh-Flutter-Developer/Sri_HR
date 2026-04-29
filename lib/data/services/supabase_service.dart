import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

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

  // ── Generic CRUD ──────────────────────────
  static Future<List<Map<String, dynamic>>> select(
    String table, {
    String? columns,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    var query = client.from(table).select(columns ?? '*');
    // filters applied on returned PostgrestFilterBuilder
    // (cast approach – works with Supabase Flutter 2.x)
    var result = await _applyFilters(
      client.from(table).select(columns ?? '*'),
      filters,
    ).order(orderBy ?? 'created_at', ascending: ascending);
    if (limit != null) {
      return (await client.from(table).select(columns ?? '*').limit(limit))
          as List<Map<String, dynamic>>;
    }
    return (result as List).cast<Map<String, dynamic>>();
  }

  static dynamic _applyFilters(dynamic query, Map<String, dynamic>? filters) {
    if (filters == null) return query;
    filters.forEach((key, value) {
      query = query.eq(key, value);
    });
    return query;
  }

  static Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await client.from(table).insert(data).select().single();
      return res;
    } catch (e) {
      log("ERROR:$e");
    }
    return {};
  }

  static Future<Map<String, dynamic>> update(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    final res = await client
        .from(table)
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return res;
  }

  static Future<void> delete(String table, String id) async {
    await client.from(table).delete().eq('id', id);
  }

  static Future<Map<String, dynamic>?> selectOne(
    String table, {
    String? columns,
    required String id,
  }) async {
    final res = await client
        .from(table)
        .select(columns ?? '*')
        .eq('id', id)
        .maybeSingle();
    return res;
  }

  // ── Storage ───────────────────────────────
  static Future<String> uploadFile(
    String bucket,
    String path,
    dynamic file, {
    String? contentType,
  }) async {
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
  }

  static Future<void> deleteFile(String bucket, String path) async {
    await client.storage.from(bucket).remove([path]);
  }

  // ── RPC / Functions ───────────────────────
  static Future<dynamic> rpc(String fn, {Map<String, dynamic>? params}) async {
    return await client.rpc(fn, params: params);
  }
}
