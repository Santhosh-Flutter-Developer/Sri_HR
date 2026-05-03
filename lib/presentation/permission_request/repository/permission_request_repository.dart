import 'package:sri_hr/data/models/permission_request_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';

class PermissionRepository {
  Future<List<PermissionRequestModel>> getPermissions(
    String companyId, {
    String? employeeId,
    String? status,
    DateTime? date,
  }) async {
    var query = SupabaseService.client
        .from('permission_requests')
        .select(
          '*, employees(full_name, employee_code, departments(name), roles(name))',
        )
        .eq('company_id', companyId);
    if (employeeId != null) query = query.eq('employee_id', employeeId);
    if (status != null) query = query.eq('status', status);
    if (date != null) {
      query = query.eq('request_date', date.toIso8601String().substring(0, 10));
    }
    final rows = await query.order('created_at', ascending: false);
    return rows
        .map<PermissionRequestModel>((r) => PermissionRequestModel.fromJson(r))
        .toList();
  }

  Future<PermissionRequestModel> createPermission(
    Map<String, dynamic> data,
  ) async {
    final row = await SupabaseService.insert('permission_requests', data);
    return PermissionRequestModel.fromJson(row);
  }

  Future<PermissionRequestModel> updatePermissionStatus(
    String id,
    String status,
    String approvedBy,
  ) async {
    final row = await SupabaseService.update('permission_requests', id, {
      'status': status,
      'approved_by': approvedBy,
      'approved_at': DateTime.now().toIso8601String(),
    });
    return PermissionRequestModel.fromJson(row);
  }

  Future<void> deletePermission(String id) =>
      SupabaseService.delete('permission_requests', id);
}
