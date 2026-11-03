import 'package:sri_hr/data/models/employee_model.dart';
import 'package:sri_hr/data/utils/network_time.dart';

enum LeaveStatus { pending, approved, rejected }

/// Which part of the day a leave covers.
///   full        – whole day(s)
///   firstHalf   – morning   (shift start → lunch start)
///   secondHalf  – afternoon (lunch start → shift end)
enum LeaveDayType {
  full('full', 'Full Day', ''),
  firstHalf('first_half', 'First Half', '1st Half'),
  secondHalf('second_half', 'Second Half', '2nd Half');

  const LeaveDayType(this.value, this.label, this.shortLabel);
  final String value; // stored in DB (leave_requests.day_type)
  final String label; // form / card label
  final String shortLabel; // compact label for report badges

  bool get isHalf => this != LeaveDayType.full;

  static LeaveDayType fromValue(String? v) => LeaveDayType.values.firstWhere(
    (e) => e.value == v,
    orElse: () => LeaveDayType.full,
  );
}

/// 0.5 -> "0.5", 1.0 -> "1", 2.5 -> "2.5"
String formatLeaveDays(num d) =>
    d == d.truncate() ? d.truncate().toString() : d.toStringAsFixed(1);

/// Which sessions ('first' / 'second') a leave occupies on [date] (yyyy-MM-dd).
/// Both = whole day, empty = the leave doesn't cover that date.
///   • single-day half leave      -> that session only
///   • range with [startHalf]     -> first date is SECOND half only
///   • range with [endHalf]       -> last date is FIRST half only
Set<String> leaveSessionsOn({
  required String fromDate,
  required String toDate,
  required LeaveDayType dayType,
  bool startHalf = false,
  bool endHalf = false,
  required String date,
}) {
  final f = fromDate.substring(0, 10);
  final t = toDate.substring(0, 10);
  final d = date.substring(0, 10);
  if (d.compareTo(f) < 0 || d.compareTo(t) > 0) return {};
  if (dayType.isHalf) {
    return {dayType == LeaveDayType.firstHalf ? 'first' : 'second'};
  }
  if (f != t) {
    if (d == f && startHalf) return {'second'};
    if (d == t && endHalf) return {'first'};
  }
  return {'first', 'second'};
}

/// Same as [leaveSessionsOn] but as a [LeaveDayType] for that date.
LeaveDayType leaveDayTypeOn({
  required String fromDate,
  required String toDate,
  required LeaveDayType dayType,
  bool startHalf = false,
  bool endHalf = false,
  required String date,
}) {
  final s = leaveSessionsOn(
    fromDate: fromDate,
    toDate: toDate,
    dayType: dayType,
    startHalf: startHalf,
    endHalf: endHalf,
    date: date,
  );
  if (s.length == 1) {
    return s.first == 'first' ? LeaveDayType.firstHalf : LeaveDayType.secondHalf;
  }
  return LeaveDayType.full;
}

/// "1 day", "0.5 day", "3 days"
String leaveDaysText(num d) => '${formatLeaveDays(d)} day${d > 1 ? 's' : ''}';

class LeaveRequestModel {
  final String id;
  final String companyId;
  final String employeeId;
  final DateTime fromDate;
  final DateTime toDate;
  final double days;
  final LeaveDayType dayType;
  final bool startHalf; // first date of a range is a 2nd-half leave
  final bool endHalf; // last date of a range is a 1st-half leave
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
    this.dayType = LeaveDayType.full,
    this.startHalf = false,
    this.endHalf = false,
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
        days: (j['days'] as num?)?.toDouble() ?? 1,
        dayType: LeaveDayType.fromValue(j['day_type'] as String?),
        startHalf: (j['start_half'] as bool?) ?? false,
        endHalf: (j['end_half'] as bool?) ?? false,
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

  /// Short text for cards, e.g. "2.5 days · half day on last date".
  String get durationLabel {
    if (dayType.isHalf) return '${formatLeaveDays(days)} day · ${dayType.label}';
    if (startHalf && endHalf) {
      return '${leaveDaysText(days)} · half day on first & last date';
    }
    if (startHalf) return '${leaveDaysText(days)} · half day on first date';
    if (endHalf) return '${leaveDaysText(days)} · half day on last date';
    return leaveDaysText(days);
  }

  Map<String, dynamic> toJson() => {
    'company_id': companyId,
    'employee_id': employeeId,
    'from_date': fromDate.toIso8601String().substring(0, 10),
    'to_date': toDate.toIso8601String().substring(0, 10),
    'days': days,
    'day_type': dayType.value,
    'start_half': startHalf,
    'end_half': endHalf,
    'reason': reason,
    'status': status.name,
  };
}