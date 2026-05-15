import 'package:sri_hr/data/utils/network_time.dart';

class HolidayModel {
  final String id;
  final String companyId;
  final DateTime date;
  final String reason;
  final int days;

  HolidayModel({
    required this.id,
    required this.companyId,
    required this.date,
    required this.reason,
    this.days = 1,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> j) => HolidayModel(
    id: (j['id'] as String?) ?? '',
    companyId: (j['company_id'] as String?) ?? '',
    date: j['date'] != null
        ? (DateTime.tryParse(j['date'] as String) ?? NetworkTime.now())
        : NetworkTime.now(),
    reason: (j['reason'] as String?) ?? '',
    days: (j['days'] as int?) ?? 1,
  );

  Map<String, dynamic> toJson() => {
    'company_id': companyId,
    'date': date.toIso8601String().substring(0, 10),
    'reason': reason,
    'days': days,
  };
}
