class NotificationModel {
  final String id;
  final String companyId;
  final String userId;
  final String type; // 'leave' | 'permission'
  final String title;
  final String body;
  final String? refId;
  final String? status; // pending | approved | rejected
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.refId,
    this.status,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) =>
      NotificationModel(
        id: (j['id'] as String?) ?? '',
        companyId: (j['company_id'] as String?) ?? '',
        userId: (j['user_id'] as String?) ?? '',
        type: (j['type'] as String?) ?? 'leave',
        title: (j['title'] as String?) ?? '',
        body: (j['body'] as String?) ?? '',
        refId: j['ref_id'] as String?,
        status: j['status'] as String?,
        isRead: (j['is_read'] as bool?) ?? false,
        createdAt:
            DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
      );
}