import 'package:sri_hr/data/models/employee_model.dart';
import 'package:sri_hr/data/utils/network_time.dart';

enum LeaveStatus { pending, approved, rejected }

class LeaveRequestModel {
  final String id;
  final String companyId;
  final String employeeId;
  final DateTime fromDate;
  final DateTime toDate;
  final int days;
  final String? reason;
  final LeaveStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final EmployeeModel? employee;

  LeaveRequestModel({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.fromDate,
    required this.toDate,
    required this.days,
    this.reason,
    this.status = LeaveStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.employee,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> j) =>
      LeaveRequestModel(
        id: (j['id'] as String?) ?? '',
        companyId: (j['company_id'] as String?) ?? '',
        employeeId: (j['employee_id'] as String?) ?? '',
        fromDate: j['from_date'] != null
            ? (DateTime.tryParse(j['from_date'] as String) ?? NetworkTime.now())
            : NetworkTime.now(),
        toDate: j['to_date'] != null
            ? (DateTime.tryParse(j['to_date'] as String) ?? NetworkTime.now())
            : NetworkTime.now(),
        days: (j['days'] as int?) ?? 1,
        reason: j['reason'] as String?,
        status: LeaveStatus.values.firstWhere(
          (e) => e.name == (j['status'] as String? ?? ''),
          orElse: () => LeaveStatus.pending,
        ),
        approvedBy: j['approved_by'] as String?,
        approvedAt: j['approved_at'] != null
            ? DateTime.tryParse(j['approved_at'] as String)
            : null,
        employee: j['employees'] != null
            ? EmployeeModel.fromJson(j['employees'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
    'company_id': companyId,
    'employee_id': employeeId,
    'from_date': fromDate.toIso8601String().substring(0, 10),
    'to_date': toDate.toIso8601String().substring(0, 10),
    'days': days,
    'reason': reason,
    'status': status.name,
  };
}
