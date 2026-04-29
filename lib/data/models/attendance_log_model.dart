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
        id: j['id'],
        companyId: j['company_id'],
        employeeId: j['employee_id'],
        date: DateTime.parse(j['date']),
        punchTime: DateTime.parse(j['punch_time']),
        punchType: j['punch_type'] == 'in' ? PunchType.in_ : PunchType.out,
        isManual: j['is_manual'] ?? false,
        adjustedBy: j['adjusted_by'],
        latitude: j['latitude']?.toDouble(),
        longitude: j['longitude']?.toDouble(),
        employee: j['employees'] != null
            ? EmployeeModel.fromJson(j['employees'])
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
