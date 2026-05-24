import 'package:flutter/material.dart';
import 'package:sri_hr/data/models/attendance_log_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:sri_hr/data/utils/network_time.dart';

class AttendanceRepository {
  Future<List<AttendanceLogModel>> getAttendanceLogs(
    String companyId, {
    DateTime? date,
    DateTime? fromDate,
    DateTime? toDate,
    String? employeeId,
    String? departmentId,
  }) async {
    if (companyId.isEmpty) return [];
    const empSelect =
        '*, employees(id, company_id, department_id, role_id, '
        'employee_code, full_name, mobile, email, profile_picture, '
        'is_active, casual_leave, mobile_login, outside_office, '
        'departments(id, company_id, code, name), '
        'roles(id, company_id, name, is_admin))';

    var query = SupabaseService.client
        .from('attendance_logs')
        .select(empSelect)
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
    final result = <AttendanceLogModel>[];
    for (final r in rows) {
      try {
        result.add(AttendanceLogModel.fromJson(r));
      } catch (e) {
        debugPrint('[AttendRepo] parse error: $e');
      }
    }
    return result;
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

  /// Upsert logic: if same employee + same date + same punch_type already exists
  /// as a manual entry, UPDATE it instead of inserting a duplicate.
  Future<AttendanceLogModel> adjustPunch(Map<String, dynamic> data) async {
    final row = await SupabaseService.client
        .from('attendance_logs')
        .insert({...data, 'is_manual': true})
        .select('id')
        .single();
    return fetchLog(row['id'] as String);
  }

  Future<AttendanceLogModel> fetchLog(String id) async {
    const empSelect =
        '*, employees(id, company_id, department_id, role_id, '
        'employee_code, full_name, mobile, email, profile_picture, '
        'is_active, casual_leave, mobile_login, outside_office, '
        'departments(id, company_id, code, name), '
        'roles(id, company_id, name, is_admin))';
    final row = await SupabaseService.client
        .from('attendance_logs')
        .select(empSelect)
        .eq('id', id)
        .single();
    return AttendanceLogModel.fromJson(row);
  }

  Future<AttendanceLogModel?> getTodayAttendance(String employeeId) async {
    await NetworkTime.syncTime();
    final today = NetworkTime.now().toIso8601String().substring(0, 10);
    try {
      final data = await SupabaseService.client
          .from('attendance_logs')
          .select()
          .eq('employee_id', employeeId)
          .eq('date', today);

      int ind = data.indexWhere((e) => e["punch_type"] == "in");
      if (ind.toString() != "-1") {
        return AttendanceLogModel.fromJson(data[ind]);
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
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
