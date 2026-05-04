import 'package:flutter/material.dart';
import 'package:sri_hr/data/models/leave_request_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';

class LeaveRepository {
  Future<List<LeaveRequestModel>> getLeaveRequests(
    String companyId, {
    String? employeeId,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (companyId.isEmpty) return [];
    var query = SupabaseService.client
        .from('leave_requests')
        .select(
          '*, employees(id, company_id, user_id, department_id, role_id, employee_code, full_name, mobile, email, profile_picture, is_active, casual_leave, mobile_login, outside_office, departments(id, company_id, code, name, mobile_login, outside_attendance), roles(id, company_id, name, is_admin, casual_leave))',
        )
        .eq('company_id', companyId);
    if (employeeId != null) query = query.eq('employee_id', employeeId);
    if (status != null) query = query.eq('status', status);
    if (fromDate != null) {
      query = query.gte(
        'from_date',
        fromDate.toIso8601String().substring(0, 10),
      );
    }
    if (toDate != null) {
      query = query.lte('to_date', toDate.toIso8601String().substring(0, 10));
    }
    final rows = await query.order('created_at', ascending: false);
    // Parse safely, skip any rows that fail
    final result = <LeaveRequestModel>[];
    for (final r in rows) {
      try {
        result.add(LeaveRequestModel.fromJson(r));
      } catch (e) {
        debugPrint('[LeaveRepo] parse error for row $r: $e');
      }
    }
    return result;
  }

  Future<LeaveRequestModel> createLeave(Map<String, dynamic> data) async {
    // Insert and get the id only
    final row = await SupabaseService.client
        .from('leave_requests')
        .insert(data)
        .select('id')
        .single();
    final id = row['id'] as String;
    // Re-fetch with full employee joins so name/dept/role are populated
    return _fetchOne(id);
  }

  Future<LeaveRequestModel> _fetchOne(String id) async {
    final row = await SupabaseService.client
        .from('leave_requests')
        .select(
          '*, employees(id, company_id, user_id, department_id, role_id, employee_code, full_name, mobile, email, profile_picture, is_active, casual_leave, mobile_login, outside_office, departments(id, company_id, code, name, mobile_login, outside_attendance), roles(id, company_id, name, is_admin, casual_leave))',
        )
        .eq('id', id)
        .single();
    return LeaveRequestModel.fromJson(row);
  }

  Future<LeaveRequestModel> updateLeaveStatus(
    String id,
    String status,
    String approvedBy,
  ) async {
    await SupabaseService.client
        .from('leave_requests')
        .update({
          'status': status,
          'approved_by': approvedBy,
          'approved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
    return _fetchOne(id);
  }

  Future<void> deleteLeave(String id) =>
      SupabaseService.delete('leave_requests', id);

  Future<int> getLeaveCount(String companyId, DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final res = await SupabaseService.client
        .from('leave_requests')
        .select()
        .eq('company_id', companyId)
        .eq('status', 'approved')
        .lte('from_date', dateStr)
        .gte('to_date', dateStr)
        .count();
    return res.count;
  }
}
