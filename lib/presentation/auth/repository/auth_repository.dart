// lib/data/repositories/auth_repository.dart
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {

  Future<String?> checkKioskLogin(String username, String password) async {
    try {
      final result = await SupabaseService.client.rpc(
        'check_kiosk_login',
        params: {'p_username': username, 'p_password': password},
      );
      if (result != null && result.toString().isNotEmpty) {
        return result.toString();
      }
    } catch (e) {
      debugPrint('[AuthRepo] checkKioskLogin error: $e');
    }
    return null;
  }

  Future<void> signInKioskSession() async {
    try {
      final session = SupabaseService.client.auth.currentSession;
      if (session != null) return; // already signed in
      await SupabaseService.client.auth.signInWithPassword(
        email: 'kiosk@srisoftwarez.com', // 👈 your dedicated kiosk email
        password: 'Admin123@', // 👈 your dedicated kiosk password
      );
    } catch (e) {
      log('signInKioskSession error: $e');
    }
  }

  // ── LOGIN ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(
    String emailOrUsername,
    String password,
  ) async {
    String emailToUse = emailOrUsername.trim();

    // ── Username / employee-code login ───────────────────
    if (!emailToUse.contains('@')) {
      // Use SECURITY DEFINER RPC — works even before auth.uid() exists.
      // Direct table query would fail here because RLS blocks
      // unauthenticated selects on the users table.
      String? found;

      // 1. Try username column first
      try {
        final result = await SupabaseService.client.rpc(
          'get_email_by_username',
          params: {'p_username': emailToUse},
        );
        if (result != null && result.toString().isNotEmpty) {
          found = result.toString();
        }
      } catch (e) {
        debugPrint('[AuthRepo] get_email_by_username error: $e');
      }

      // 2. Fallback: try employee_code lookup
      if (found == null || found.isEmpty) {
        try {
          final result = await SupabaseService.client.rpc(
            'get_email_by_employee_code',
            params: {'p_code': emailToUse},
          );
          if (result != null && result.toString().isNotEmpty) {
            found = result.toString();
          }
        } catch (e) {
          debugPrint('[AuthRepo] get_email_by_employee_code error: $e');
        }
      }

      if (found == null || found.isEmpty) {
        throw Exception(
          'User not registered. '
          'Check your username / employee code, or login with email.',
        );
      }
      emailToUse = found;
    }

    // ── Supabase Auth sign-in ────────────────────────────
    final AuthResponse res = await SupabaseService.auth.signInWithPassword(
      email: emailToUse,
      password: password,
    );
    if (res.user == null) throw Exception('Incorrect email or password. Please try again.');

    // ── Fetch full user profile with role ────────────────
    final userRow = await SupabaseService.client
        .from('users')
        .select('*, roles(*)')
        .eq('id', res.user!.id)
        .maybeSingle();

    if (userRow == null) {
      throw Exception(
        'Your user profile could not be loaded. Please contact your administrator.',
      );
    }
    return userRow;
  }

  // ── LOGOUT ────────────────────────────────────────────────
  Future<void> logout() => SupabaseService.signOut();

  // ── REGISTER COMPANY ─────────────────────────────────────
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
    // 1. Create Supabase Auth user
    final AuthResponse authRes = await SupabaseService.auth.signUp(
      email: email,
      password: password,
    );
    if (authRes.user == null) {
      throw Exception(
        'Could not create account. '
        'This email may already be registered.',
      );
    }
    final authUserId = authRes.user!.id;

    try {
      // 2. SECURITY DEFINER RPC creates:
      //    org → company → role → permissions → user → employee → subscription
      final result = await SupabaseService.client.rpc(
        'register_company',
        params: {
          'p_auth_user_id': authUserId,
          'p_company_name': companyName.trim().isEmpty?null: companyName.trim(),
          'p_person_name': personName.trim().isEmpty ? null :personName.trim(),
          'p_gstin': gstin.trim().isEmpty ? null : gstin.trim(),
          'p_mobile': mobile.trim().isEmpty ? null :mobile.trim(),
          'p_email': email.trim().isEmpty ? null :email.trim(),
          'p_address': address.trim().isEmpty ? null :address.trim(),
          'p_country': country.trim().isEmpty ? null :country.trim(),
          'p_state': state.trim().isEmpty ? null :state.trim(),
          'p_city': city.trim().isEmpty ? null :city.trim(),
          'p_pincode': pincode.trim().isEmpty ? null :pincode.trim(),
        },
      );

      if (result is Map) return Map<String, dynamic>.from(result);
      return {'user_id': authUserId};
    } catch (e) {
      // Clean up orphaned auth user so they can retry
      await SupabaseService.auth.signOut();
      rethrow;
    }
  }

  // ── PERMISSIONS ───────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getRolePermissions(String roleId) async {
    final rows = await SupabaseService.client
        .from('role_permissions')
        .select()
        .eq('role_id', roleId);
    return rows.cast<Map<String, dynamic>>();
  }

  // ── SUBSCRIPTION ──────────────────────────────────────────
  Future<Map<String, dynamic>?> getSubscription(String companyId) async {
    return await SupabaseService.client
        .from('subscriptions')
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }
}
