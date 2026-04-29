
import 'package:sri_hr/data/models/employee_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';

class EmployeeRepository {
  Future<List<EmployeeModel>> getEmployees(String companyId, {
    String? departmentId, String? roleId, bool? isActive,
  }) async {
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

  Future<String> generateEmployeeCode(String companyId) async {
    final rows = await SupabaseService.client
        .from('employees')
        .select('employee_code')
        .eq('company_id', companyId)
        .order('created_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return 'EMP001';
    final last = rows.first['employee_code'] as String;
    final num = int.tryParse(last.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return 'EMP${(num + 1).toString().padLeft(3, '0')}';
  }

  Future<EmployeeModel> createEmployee(Map<String, dynamic> data) async {
    final row = await SupabaseService.insert('employees', data);
    return EmployeeModel.fromJson(row);
  }

  Future<EmployeeModel> updateEmployee(String id, Map<String, dynamic> data) async {
    final row = await SupabaseService.update('employees', id, data);
    return EmployeeModel.fromJson(row);
  }

  Future<void> deleteEmployee(String id) => SupabaseService.delete('employees', id);

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