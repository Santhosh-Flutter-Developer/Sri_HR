import 'package:flutter/material.dart';
import 'package:sri_hr/data/models/permission_request_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:sri_hr/data/utils/network_time.dart';

class PermissionRepository {
  static const _permEmpSelect =
      '*, employees(id, company_id, user_id, department_id, role_id, '
      'employee_code, full_name, mobile, email, profile_picture, '
      'is_active, casual_leave, mobile_login, outside_office, '
      'departments(id, company_id, code, name, mobile_login, outside_attendance), '
      'roles(id, company_id, name, is_admin, casual_leave))';

  Future<List<PermissionRequestModel>> getPermissions(
    String companyId, {
    String? employeeId,
    String? status,
    DateTime? date,
  }) async {
    if (companyId.isEmpty) return [];
    var query = SupabaseService.client
        .from('permission_requests')
        .select(_permEmpSelect)
        .eq('company_id', companyId);
    if (employeeId != null) query = query.eq('employee_id', employeeId);
    if (status != null) query = query.eq('status', status);
    if (date != null) {
      query = query.eq('request_date', date.toIso8601String().substring(0, 10));
    }
    final rows = await query.order('created_at', ascending: false);
    final result = <PermissionRequestModel>[];
    for (final r in rows) {
      try {
        result.add(PermissionRequestModel.fromJson(r));
      } catch (e) {
        debugPrint('[PermRepo] parse error: $e\nrow: $r');
      }
    }
    return result;
  }

  Future<PermissionRequestModel> createPermission(
    Map<String, dynamic> data,
  ) async {
    final row = await SupabaseService.client
        .from('permission_requests')
        .insert(data)
        .select('id')
        .single();
    return _fetchPermOne(row['id'] as String);
  }

  Future<PermissionRequestModel> _fetchPermOne(String id) async {
    final row = await SupabaseService.client
        .from('permission_requests')
        .select(_permEmpSelect)
        .eq('id', id)
        .single();
    return PermissionRequestModel.fromJson(row);
  }

  Future<PermissionRequestModel> updatePermissionStatus(
    String id,
    String status,
    String approvedBy,
  ) async {
    await SupabaseService.client
        .from('permission_requests')
        .update({
          'status': status,
          'approved_by': approvedBy,
          'approved_at': NetworkTime.now().toIso8601String(),
        })
        .eq('id', id);
    return _fetchPermOne(id);
  }

  Future<void> deletePermission(String id) =>
      SupabaseService.delete('permission_requests', id);
}
