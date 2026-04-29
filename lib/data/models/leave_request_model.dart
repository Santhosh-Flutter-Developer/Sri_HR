import 'package:sri_hr/data/models/employee_model.dart';

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
        id: j['id'],
        companyId: j['company_id'],
        employeeId: j['employee_id'],
        fromDate: DateTime.parse(j['from_date']),
        toDate: DateTime.parse(j['to_date']),
        days: j['days'] ?? 1,
        reason: j['reason'],
        status: LeaveStatus.values.firstWhere(
          (e) => e.name == j['status'],
          orElse: () => LeaveStatus.pending,
        ),
        approvedBy: j['approved_by'],
        approvedAt: j['approved_at'] != null
            ? DateTime.parse(j['approved_at'])
            : null,
        employee: j['employees'] != null
            ? EmployeeModel.fromJson(j['employees'])
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
