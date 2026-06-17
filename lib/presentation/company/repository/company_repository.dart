import 'package:sri_hr/data/models/company_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';

class CompanyRepository {
  Future<CompanyModel?> getCompany(String companyId) async {
    final row = await SupabaseService.selectOne('companies', id: companyId);
    return row != null ? CompanyModel.fromJson(row) : null;
  }

  Future<CompanyModel> updateCompany(
    String id,
    Map<String, dynamic> data,
  ) async {
    final row = await SupabaseService.update('companies', id, data);
    return CompanyModel.fromJson(row);
  }

  // ── Duplicate checks for branch fields ──────────────────

  /// Returns true if [name] is already used by another branch in the same org.
  /// Pass [excludeCompanyId] when editing so the current branch is excluded.
  Future<bool> isBranchNameExists(
    String name,
    String orgId, {
    String? excludeCompanyId,
  }) async {
    var query = SupabaseService.client
        .from('companies')
        .select('id')
        .eq('org_id', orgId)
        .ilike('name', name.trim());

    if (excludeCompanyId != null) {
      query = query.neq('id', excludeCompanyId);
    }

    final rows = await query.limit(1);
    return (rows as List).isNotEmpty;
  }

  /// Returns true if [branchCode] is already used by another branch in the same org.
  Future<bool> isBranchCodeExists(
    String branchCode,
    String orgId, {
    String? excludeCompanyId,
  }) async {
    var query = SupabaseService.client
        .from('companies')
        .select('id')
        .eq('org_id', orgId)
        .ilike('branch_code', branchCode.trim());

    if (excludeCompanyId != null) {
      query = query.neq('id', excludeCompanyId);
    }

    final rows = await query.limit(1);
    return (rows as List).isNotEmpty;
  }

  /// Returns true if [gstin] is already used by ANY company globally.
  /// Pass [excludeCompanyId] when editing so the current branch is excluded.
  Future<bool> isGstinExists(
    String gstin, {
    String? excludeCompanyId,
  }) async {
    final result = await SupabaseService.client.rpc(
      'check_gstin_globally_exists',
      params: {
        'p_gstin': gstin.trim().toUpperCase(),
        'p_exclude_company_id': excludeCompanyId,
      },
    );
    return result as bool;
  }

  /// Returns true if [phone] is already used by another branch in the same org.
  Future<bool> isBranchPhoneExists(
    String phone,
    String orgId, {
    String? excludeCompanyId,
  }) async {
    var query = SupabaseService.client
        .from('companies')
        .select('id')
        .eq('org_id', orgId)
        .eq('phone', phone.trim());

    if (excludeCompanyId != null) {
      query = query.neq('id', excludeCompanyId);
    }

    final rows = await query.limit(1);
    return (rows as List).isNotEmpty;
  }

  /// Returns true if [email] is already used by another branch in the same org.
  Future<bool> isBranchEmailExists(
    String email,
    String orgId, {
    String? excludeCompanyId,
  }) async {
    var query = SupabaseService.client
        .from('companies')
        .select('id')
        .eq('org_id', orgId)
        .ilike('email', email.trim());

    if (excludeCompanyId != null) {
      query = query.neq('id', excludeCompanyId);
    }

    final rows = await query.limit(1);
    return (rows as List).isNotEmpty;
  }

  // ── GLOBAL uniqueness checks (across ALL orgs + employees) ──

  /// Returns true if [phone] exists in **any** company OR any employee record
  /// anywhere in the system. Pass [excludeCompanyId] when editing a branch.
  Future<bool> isPhoneGloballyExists(
    String phone, {
    String? excludeCompanyId,
  }) async {
    final result = await SupabaseService.client.rpc(
      'check_phone_globally_exists',
      params: {
        'p_phone': phone.trim(),
        'p_exclude_company_id': excludeCompanyId,
        'p_exclude_employee_id': null,
      },
    );
    return result as bool;
  }

  /// Returns true if [email] exists in **any** company OR any employee record
  /// anywhere in the system. Pass [excludeCompanyId] when editing a branch.
  Future<bool> isEmailGloballyExists(
    String email, {
    String? excludeCompanyId,
  }) async {
    final result = await SupabaseService.client.rpc(
      'check_email_globally_exists',
      params: {
        'p_email': email.trim().toLowerCase(),
        'p_exclude_company_id': excludeCompanyId,
        'p_exclude_employee_id': null,
      },
    );
    return result as bool;
  }
}