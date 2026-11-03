import 'package:flutter/material.dart';
import 'package:sri_hr/data/models/leave_request_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
import 'package:sri_hr/data/utils/network_time.dart';

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

  /// True if the requested leave clashes with an existing pending/approved one.
  ///
  /// Checked per date and per session: two leaves clash only if they both
  /// occupy the same session (first/second half) on at least one date. So
  /// "First Half 05 Nov" + "Second Half 05 Nov", or a 2.5-day leave ending
  /// with a first half + a Second Half on its last date, can co-exist.
  Future<bool> hasOverlappingLeave({
    required String companyId,
    required String employeeId,
    required String fromDate,
    required String toDate,
    LeaveDayType dayType = LeaveDayType.full,
    bool startHalf = false,
    bool endHalf = false,
  }) async {
    // Candidate rows: existing.from_date <= new.to_date AND existing.to_date >= new.from_date
    final rows = await SupabaseService.client
        .from('leave_requests')
        .select('id, from_date, to_date, day_type, start_half, end_half')
        .eq('company_id', companyId)
        .eq('employee_id', employeeId)
        .inFilter('status', ['pending', 'approved']) // ignore rejected leaves
        .lte('from_date', toDate)
        .gte('to_date', fromDate);

    for (final r in rows) {
      final exFrom = (r['from_date'] as String).substring(0, 10);
      final exTo = (r['to_date'] as String).substring(0, 10);
      final exType = LeaveDayType.fromValue(r['day_type'] as String?);
      final exStart = (r['start_half'] as bool?) ?? false;
      final exEnd = (r['end_half'] as bool?) ?? false;

      // Walk every date of the new request and compare sessions
      var cursor = DateTime.parse(fromDate);
      final end = DateTime.parse(toDate);
      while (!cursor.isAfter(end)) {
        final ds = cursor.toIso8601String().substring(0, 10);
        final mine = leaveSessionsOn(
          fromDate: fromDate,
          toDate: toDate,
          dayType: dayType,
          startHalf: startHalf,
          endHalf: endHalf,
          date: ds,
        );
        final theirs = leaveSessionsOn(
          fromDate: exFrom,
          toDate: exTo,
          dayType: exType,
          startHalf: exStart,
          endHalf: exEnd,
          date: ds,
        );
        if (mine.intersection(theirs).isNotEmpty) return true;
        cursor = cursor.add(const Duration(days: 1));
      }
    }
    return false;
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
          'approved_at': NetworkTime.now().toIso8601String(),
        })
        .eq('id', id);
    return _fetchOne(id);
  }

  Future<void> deleteLeave(String id) =>
      SupabaseService.delete('leave_requests', id);

  /// All leave requests still waiting for approval (any date).
  Future<int> getPendingLeaveCount(String companyId) async {
    final res = await SupabaseService.client
        .from('leave_requests')
        .select()
        .eq('company_id', companyId)
        .eq('status', 'pending')
        .count();
    return res.count;
  }

  /// Employees on approved leave for the WHOLE of [date].
  /// Half-day leave is excluded — those employees still work the other half.
  Future<int> getLeaveCount(String companyId, DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = await SupabaseService.client
        .from('leave_requests')
        .select('employee_id, from_date, to_date, day_type, start_half, end_half')
        .eq('company_id', companyId)
        .eq('status', 'approved')
        .lte('from_date', dateStr)
        .gte('to_date', dateStr);

    // Union the sessions per employee (First Half + Second Half = whole day)
    final Map<String, Set<String>> covered = {};
    for (final r in rows) {
      covered.putIfAbsent(r['employee_id'] as String, () => {}).addAll(
        leaveSessionsOn(
          fromDate: r['from_date'] as String,
          toDate: r['to_date'] as String,
          dayType: LeaveDayType.fromValue(r['day_type'] as String?),
          startHalf: (r['start_half'] as bool?) ?? false,
          endHalf: (r['end_half'] as bool?) ?? false,
          date: dateStr,
        ),
      );
    }
    return covered.values.where((s) => s.length == 2).length;
  }
}