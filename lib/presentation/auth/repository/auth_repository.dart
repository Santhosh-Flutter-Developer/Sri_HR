import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  // ── LOGIN ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(
    String emailOrUsername,
    String password,
  ) async {
    String emailToUse = emailOrUsername;

    // If not an email → look up username in users table
    if (!emailOrUsername.contains('@')) {
      final row = await SupabaseService.client
          .from('users')
          .select('email')
          .eq('username', emailOrUsername)
          .maybeSingle();
      if (row == null) throw Exception('User not registered');
      emailToUse = row['email'] as String;
    }

    final AuthResponse res = await SupabaseService.auth.signInWithPassword(
      email: emailToUse,
      password: password,
    );
    if (res.user == null) throw Exception('Invalid credentials');

    final userRow = await SupabaseService.client
        .from('users')
        .select('*, roles(*)')
        .eq('id', res.user!.id)
        .maybeSingle();

    if (userRow == null) {
      throw Exception('User profile not found. Contact your administrator.');
    }
    return userRow;
  }

  // ── LOGOUT ────────────────────────────────────────────────
  Future<void> logout() => SupabaseService.signOut();

  // ── REGISTER COMPANY via SECURITY DEFINER RPC ────────────
  Future<Map<String, dynamic>> registerCompany({
    required String companyName,
    required String personName,
    required String gstin,
    required String mobile,
    required String email,
    required String address,
    required String country,
    required String state,
    required String city,
    required String pincode,
    required String password,
  }) async {
    // 1. Create Supabase Auth user first
    final AuthResponse authRes = await SupabaseService.auth.signUp(
      email: email,
      password: password,
    );
    if (authRes.user == null) {
      throw Exception(
        'Could not create account. Email may already be registered.',
      );
    }
    final authUserId = authRes.user!.id;

    try {
      // 2. Call SECURITY DEFINER RPC — bypasses ALL RLS
      final result = await SupabaseService.client.rpc(
        'register_company',
        params: {
          'p_auth_user_id': authUserId,
          'p_company_name': companyName,
          'p_person_name': personName,
          'p_gstin': gstin.trim().isEmpty ? null : gstin.trim(),
          'p_mobile': mobile,
          'p_email': email,
          'p_address': address,
          'p_country': country,
          'p_state': state,
          'p_city': city,
          'p_pincode': pincode,
        },
      );

      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return {'user_id': authUserId};
    } catch (e) {
      await SupabaseService.auth.signOut(); // clean up orphaned auth user
      rethrow;
    }
  }

  // ── HELPERS ───────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getRolePermissions(String roleId) async {
    final rows = await SupabaseService.client
        .from('role_permissions')
        .select()
        .eq('role_id', roleId);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> getSubscription(String companyId) async {
    return await SupabaseService.client
        .from('subscriptions')
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false)
        .maybeSingle();
  }
}
