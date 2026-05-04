import 'package:sri_hr/data/models/employee_model.dart';

enum PunchType { in_, out }

class AttendanceLogModel {
  final String id;
  final String companyId;
  final String employeeId;
  final DateTime date;
  final DateTime punchTime;
  final PunchType punchType;
  final bool isManual;
  final String? adjustedBy;
  final double? latitude;
  final double? longitude;
  final EmployeeModel? employee;

  AttendanceLogModel({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.date,
    required this.punchTime,
    required this.punchType,
    this.isManual = false,
    this.adjustedBy,
    this.latitude,
    this.longitude,
    this.employee,
  });

  factory AttendanceLogModel.fromJson(Map<String, dynamic> j) =>
      AttendanceLogModel(
        id: (j['id'] as String?) ?? '',
        companyId: (j['company_id'] as String?) ?? '',
        employeeId: (j['employee_id'] as String?) ?? '',
        date: j['date'] != null
            ? (DateTime.tryParse(j['date'] as String) ?? DateTime.now())
            : DateTime.now(),
        punchTime: j['punch_time'] != null
            ? (DateTime.tryParse(j['punch_time'] as String) ?? DateTime.now())
            : DateTime.now(),
        punchType: (j['punch_type'] as String?) == 'in'
            ? PunchType.in_
            : PunchType.out,
        isManual: (j['is_manual'] as bool?) ?? false,
        adjustedBy: j['adjusted_by'] as String?,
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        employee: j['employees'] != null
            ? EmployeeModel.fromJson(j['employees'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
    'company_id': companyId,
    'employee_id': employeeId,
    'date': date.toIso8601String().substring(0, 10),
    'punch_time': punchTime.toIso8601String(),
    'punch_type': punchType == PunchType.in_ ? 'in' : 'out',
    'is_manual': isManual,
    'adjusted_by': adjustedBy,
    'latitude': latitude,
    'longitude': longitude,
  };
}
