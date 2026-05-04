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

  Future<EmployeeModel?> getEmployee(String id) async {
    final row = await SupabaseService.client
        .from('employees')
        .select('*, departments(*), roles(*)')
        .eq('id', id)
        .maybeSingle();
    return row != null ? EmployeeModel.fromJson(row) : null;
  }

  /// Generates a unique employee code that is unique across the ENTIRE
  /// organization (all branches), not just within one company.
  /// Format: [BranchPrefix]-EMP[NNN]  e.g. HQ-EMP001, BR1-EMP001
  /// The numeric part is org-wide so no two employees share the same number.
  Future<String> generateEmployeeCode(String companyId) async {
    final client = SupabaseService.client;

    // 1. Get branch code for prefix
    String branchPrefix = '';
    try {
      final companyRow = await client
          .from('companies')
          .select('branch_code')
          .eq('id', companyId)
          .maybeSingle();
      final code = companyRow?['branch_code'] as String?;
      if (code != null && code.isNotEmpty) {
        branchPrefix = '${code.toUpperCase()}-';
      }
    } catch (_) {}

    // 2. Find highest numeric code across ALL branches in the org
    //    (join via user_company_access to find all sibling companies)
    try {
      final orgRows = await client
          .from('user_company_access')
          .select('company_id')
          .eq('user_id', client.auth.currentUser?.id ?? '');

      final allCompanyIds = orgRows
          .map((r) => r['company_id'] as String)
          .toList();

      // If org has multiple branches, find max code number across all
      if (allCompanyIds.isNotEmpty) {
        final empRows = await client
            .from('employees')
            .select('employee_code')
            .inFilter('company_id', allCompanyIds)
            .order('created_at', ascending: false);

        if (empRows.isNotEmpty) {
          // Extract max numeric part from all codes
          int maxNum = 0;
          for (final row in empRows) {
            final codeStr = row['employee_code'] as String? ?? '';
            final num =
                int.tryParse(codeStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            if (num > maxNum) maxNum = num;
          }
          return '$branchPrefix'
              'EMP${(maxNum + 1).toString().padLeft(3, '0')}';
        }
      }
    } catch (_) {}

    // 3. Fallback: check only within current company
    final rows = await client
        .from('employees')
        .select('employee_code')
        .eq('company_id', companyId)
        .order('created_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return '${branchPrefix}EMP001';
    final last = rows.first['employee_code'] as String? ?? '';
    final num = int.tryParse(last.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return '$branchPrefix'
        'EMP${(num + 1).toString().padLeft(3, '0')}';
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
}
