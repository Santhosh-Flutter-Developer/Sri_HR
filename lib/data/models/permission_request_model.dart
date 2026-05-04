import 'package:sri_hr/data/models/employee_model.dart';
import 'package:sri_hr/data/models/leave_request_model.dart';

class PermissionRequestModel {
  final String id;
  final String companyId;
  final String employeeId;
  final DateTime requestDate;
  final String fromTime;
  final String toTime;
  final int? minutes;
  final String? reason;
  final LeaveStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final EmployeeModel? employee;

  PermissionRequestModel({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.requestDate,
    required this.fromTime,
    required this.toTime,
    this.minutes,
    this.reason,
    this.status = LeaveStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.employee,
  });

  factory PermissionRequestModel.fromJson(Map<String, dynamic> j) =>
      PermissionRequestModel(
        id: (j['id'] as String?) ?? '',
        companyId: (j['company_id'] as String?) ?? '',
        employeeId: (j['employee_id'] as String?) ?? '',
        requestDate: j['request_date'] != null
            ? (DateTime.tryParse(j['request_date'] as String) ?? DateTime.now())
            : DateTime.now(),
        fromTime: (j['from_time'] as String?) ?? '',
        toTime: (j['to_time'] as String?) ?? '',
        minutes: j['minutes'] as int?,
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
    'request_date': requestDate.toIso8601String().substring(0, 10),
    'from_time': fromTime,
    'to_time': toTime,
    'minutes': minutes,
    'reason': reason,
    'status': status.name,
  };
}
