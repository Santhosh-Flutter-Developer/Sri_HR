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
        id: j['id'],
        companyId: j['company_id'],
        date: DateTime.parse(j['date']),
        reason: j['reason'],
        days: j['days'] ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'date': date.toIso8601String().substring(0, 10),
        'reason': reason,
        'days': days,
      };
}