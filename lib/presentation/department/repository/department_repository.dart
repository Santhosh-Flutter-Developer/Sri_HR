import 'package:sri_hr/data/models/department_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';

class DepartmentRepository {
  Future<List<DepartmentModel>> getDepartments(String companyId) async {
    final rows = await SupabaseService.client
        .from('departments')
        .select()
        .eq('company_id', companyId)
        .order('name');
    return rows
        .map<DepartmentModel>((r) => DepartmentModel.fromJson(r))
        .toList();
  }

  Future<DepartmentModel> createDepartment(Map<String, dynamic> data) async {
    final row = await SupabaseService.insert('departments', data);
    return DepartmentModel.fromJson(row);
  }

  Future<DepartmentModel> updateDepartment(
    String id,
    Map<String, dynamic> data,
  ) async {
    final row = await SupabaseService.update('departments', id, data);
    return DepartmentModel.fromJson(row);
  }

  Future<void> deleteDepartment(String id) =>
      SupabaseService.delete('departments', id);
}
