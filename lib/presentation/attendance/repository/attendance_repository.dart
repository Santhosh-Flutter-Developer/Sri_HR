import 'package:sri_hr/data/models/attendance_log_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';

class AttendanceRepository {
  Future<List<AttendanceLogModel>> getAttendanceLogs(
    String companyId, {
    DateTime? date,
    DateTime? fromDate,
    DateTime? toDate,
    String? employeeId,
    String? departmentId,
  }) async {
    var query = SupabaseService.client
        .from('attendance_logs')
        .select('*, employees(*, departments(*))')
        .eq('company_id', companyId);

    if (date != null) {
      query = query.eq('date', date.toIso8601String().substring(0, 10));
    }
    if (fromDate != null) {
      query = query.gte('date', fromDate.toIso8601String().substring(0, 10));
    }
    if (toDate != null) {
      query = query.lte('date', toDate.toIso8601String().substring(0, 10));
    }
    if (employeeId != null) query = query.eq('employee_id', employeeId);

    final rows = await query.order('punch_time');
    return rows
        .map<AttendanceLogModel>((r) => AttendanceLogModel.fromJson(r))
        .toList();
  }

  Future<AttendanceLogModel> punchIn(Map<String, dynamic> data) async {
    final row = await SupabaseService.insert('attendance_logs', {
      ...data,
      'punch_type': 'in',
    });
    return AttendanceLogModel.fromJson(row);
  }

  Future<AttendanceLogModel> punchOut(Map<String, dynamic> data) async {
    final row = await SupabaseService.insert('attendance_logs', {
      ...data,
      'punch_type': 'out',
    });
    return AttendanceLogModel.fromJson(row);
  }

  Future<AttendanceLogModel> adjustPunch(Map<String, dynamic> data) async {
    final row = await SupabaseService.insert('attendance_logs', {
      ...data,
      'is_manual': true,
    });
    return AttendanceLogModel.fromJson(row);
  }

  Future<void> deleteLog(String id) =>
      SupabaseService.delete('attendance_logs', id);

  Future<int> getPresentCount(String companyId, DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final res = await SupabaseService.client
        .from('attendance_logs')
        .select('employee_id')
        .eq('company_id', companyId)
        .eq('date', dateStr)
        .eq('punch_type', 'in')
        .count();
    return res.count;
  }
}
