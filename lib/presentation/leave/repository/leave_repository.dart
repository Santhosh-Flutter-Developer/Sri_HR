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
    var query = SupabaseService.client
        .from('leave_requests')
        .select(
          '*, employees(full_name, employee_code, departments(name), roles(name))',
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
    return rows
        .map<LeaveRequestModel>((r) => LeaveRequestModel.fromJson(r))
        .toList();
  }

  Future<LeaveRequestModel> createLeave(Map<String, dynamic> data) async {
    final row = await SupabaseService.insert('leave_requests', data);
    return LeaveRequestModel.fromJson(row);
  }

  Future<LeaveRequestModel> updateLeaveStatus(
    String id,
    String status,
    String approvedBy,
  ) async {
    final row = await SupabaseService.update('leave_requests', id, {
      'status': status,
      'approved_by': approvedBy,
      'approved_at': DateTime.now().toIso8601String(),
    });
    return LeaveRequestModel.fromJson(row);
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
