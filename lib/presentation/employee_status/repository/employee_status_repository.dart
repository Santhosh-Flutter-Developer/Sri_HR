import 'package:sri_hr/data/models/employee_status_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';

class EmployeeStatusRepository {
  Future<List<EmployeeStatusModel>> getStatuses(String companyId) async {
    final rows = await SupabaseService.client
        .from('employee_statuses')
        .select()
        .eq('company_id', companyId)
        .order('name');
    return rows
        .map<EmployeeStatusModel>((r) => EmployeeStatusModel.fromJson(r))
        .toList();
  }

  Future<EmployeeStatusModel> create(Map<String, dynamic> data) async {
    final row = await SupabaseService.insert('employee_statuses', data);
    return EmployeeStatusModel.fromJson(row);
  }

  Future<EmployeeStatusModel> update(
    String id,
    Map<String, dynamic> data,
  ) async {
    final row = await SupabaseService.update('employee_statuses', id, data);
    return EmployeeStatusModel.fromJson(row);
  }

  Future<void> delete(String id) =>
      SupabaseService.delete('employee_statuses', id);
}
