import 'package:sri_hr/data/models/notification_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';

class NotificationRepository {
  /// Only UNREAD notifications – read ones are hidden from the list.
  Future<List<NotificationModel>> getUnread(String userId) async {
    final rows = await SupabaseService.client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('is_read', false)
        .order('created_at', ascending: false)
        .limit(100);
    return (rows as List)
        .map((r) => NotificationModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(String id) => SupabaseService.client
      .from('notifications')
      .update({
        'is_read': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      })
      .eq('id', id);

  Future<void> markAllRead(String userId) => SupabaseService.client
      .from('notifications')
      .update({
        'is_read': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      })
      .eq('user_id', userId)
      .eq('is_read', false);
}