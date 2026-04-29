enum SubscriptionPlan { trial, basic, pro, premium }

enum SubscriptionStatus { active, expired, cancelled }

class SubscriptionModel {
  final String id;
  final String companyId;
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final int userLimit;
  final DateTime startDate;
  final DateTime expiryDate;
  final String? paymentId;
  final String paymentStatus;
  final double amount;
  final String duration;

  SubscriptionModel({
    required this.id,
    required this.companyId,
    required this.plan,
    required this.status,
    required this.userLimit,
    required this.startDate,
    required this.expiryDate,
    this.paymentId,
    this.paymentStatus = 'pending',
    this.amount = 0,
    this.duration = 'trial',
  });

  bool get isActive =>
      status == SubscriptionStatus.active && expiryDate.isAfter(DateTime.now());
  bool get isExpiringSoon =>
      isActive && expiryDate.difference(DateTime.now()).inDays <= 2;
  int get daysRemaining => expiryDate.difference(DateTime.now()).inDays;

  factory SubscriptionModel.fromJson(Map<String, dynamic> j) =>
      SubscriptionModel(
        id: j['id'],
        companyId: j['company_id'],
        plan: SubscriptionPlan.values.firstWhere(
          (e) => e.name == j['plan'],
          orElse: () => SubscriptionPlan.trial,
        ),
        status: SubscriptionStatus.values.firstWhere(
          (e) => e.name == j['status'],
          orElse: () => SubscriptionStatus.expired,
        ),
        userLimit: j['user_limit'] ?? 3,
        startDate: DateTime.parse(j['start_date']),
        expiryDate: DateTime.parse(j['expiry_date']),
        paymentId: j['payment_id'],
        paymentStatus: j['payment_status'] ?? 'pending',
        amount: (j['amount'] ?? 0).toDouble(),
        duration: j['duration'] ?? 'trial',
      );
}
