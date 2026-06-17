import 'package:sri_hr/data/models/employee_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';

class EmployeeRepository {
  Future<List<EmployeeModel>> getEmployees(
    String companyId, {
    String? departmentId,
    String? roleId,
    bool? isActive,
  }) async {
    // Use left join style by selecting nullable joined tables
    var query = SupabaseService.client
        .from('employees')
        .select('*, departments(*), roles(*)')
        .eq('company_id', companyId);
    if (departmentId != null) query = query.eq('department_id', departmentId);
    if (roleId != null) query = query.eq('role_id', roleId);
    if (isActive != null) query = query.eq('is_active', isActive);
    final rows = await query.order('full_name');
    return rows.map<EmployeeModel>((r) => EmployeeModel.fromJson(r)).toList();
  }

  Future<List<EmployeeModel>> getAllEmployees(String companyId) async {
    final res = await SupabaseService.client
        .from('employees')
        .select()
        .eq('company_id', companyId)
        .eq('is_active', true);
    return (res as List).map((e) => EmployeeModel.fromJson(e)).toList();
  }

  Future<EmployeeModel?> getEmployee(String id) async {
    final row = await SupabaseService.client
        .from('employees')
        .select('*, departments(*), roles(*)')
        .eq('id', id)
        .maybeSingle();
    return row != null ? EmployeeModel.fromJson(row) : null;
  }

  Future<bool> isMobileExists(
    String mobile, {
    String? excludeEmployeeId,
  }) async {
    final result = await SupabaseService.client.rpc(
      'check_mobile_exists',
      params: {
        'p_mobile': mobile.trim(),
        'p_exclude_company_id': null,
        'p_exclude_employee_id': excludeEmployeeId,
      },
    );
    return result as bool;
  }

  Future<bool> isEmailExists(String email, {String? excludeEmployeeId}) async {
    final result = await SupabaseService.client.rpc(
      'check_email_globally_exists',
      params: {
        'p_email': email.trim().toLowerCase(),
        'p_exclude_company_id': null,
        'p_exclude_employee_id': ?excludeEmployeeId,
      },
    );
    return result as bool;
  }

  Future<EmployeeModel?> getEmployeeUserId(String id) async {
    final row = await SupabaseService.client
        .from('employees')
        .select('*, departments(*), roles(*)')
        .eq('user_id', id)
        .maybeSingle();
    return row != null ? EmployeeModel.fromJson(row) : null;
  }

  // Preview only — does NOT reserve the code
  // Called when form opens
  Future<String> previewEmployeeCode(String companyId) async {
    final result = await SupabaseService.client.rpc(
      'preview_emp_code',
      params: {'p_company_id': companyId},
    );
    if (result == null) throw Exception('Could not preview the employee code. Please try again.');
    return result as String;
  }

  // Reserve + generate — called only when actually saving
  // This is your existing method, keep it as is
  Future<String> generateEmployeeCode(String companyId) async {
    final result = await SupabaseService.client.rpc(
      'generate_emp_code',
      params: {'p_company_id': companyId},
    );
    if (result == null) throw Exception('Could not generate an employee code. Please try again or enter one manually.');
    return result as String;
  }

  Future<EmployeeModel> createEmployee(Map<String, dynamic> data) async {
    // Insert and get back just the id (avoids column mismatch on select *)
    final row = await SupabaseService.client
        .from('employees')
        .insert(data)
        .select('id')
        .single();
    final id = row['id'] as String;
    // Fetch full record with joins
    final full = await getEmployee(id);
    return full ?? EmployeeModel.fromJson({...data, 'id': id});
  }

  Future<EmployeeModel> updateEmployee(
    String id,
    Map<String, dynamic> data,
  ) async {
    await SupabaseService.client.from('employees').update(data).eq('id', id);
    final full = await getEmployee(id);
    return full ?? EmployeeModel.fromJson({...data, 'id': id});
  }

  Future<void> deleteEmployee(String id) =>
      SupabaseService.delete('employees', id);

  Future<int> countEmployees(String companyId) async {
    final res = await SupabaseService.client
        .from('employees')
        .select()
        .eq('company_id', companyId)
        .eq('is_active', true)
        .count();
    return res.count;
  }

  Future<int> countEmployeesByOrg(String orgId) async {
    // Get all company IDs that belong to this org
    final companies = await SupabaseService.client
        .from('companies')
        .select('id')
        .eq('org_id', orgId)
        .eq('is_active', true);

    if ((companies as List).isEmpty) return 0;

    final companyIds = companies.map((c) => c['id'] as String).toList();

    // Count active employees across all those branches
    final res = await SupabaseService.client
        .from('employees')
        .select()
        .inFilter('company_id', companyIds)
        .eq('is_active', true)
        .count();

    return res.count;
  }
}
