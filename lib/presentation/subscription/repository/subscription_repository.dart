import 'package:sri_hr/data/models/subscription_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';

class SubscriptionRepository {
  Future<SubscriptionModel?> getActiveSubscription(String companyId) async {
    final row = await SupabaseService.client
        .from('subscriptions')
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false)
        .maybeSingle();
    return row != null ? SubscriptionModel.fromJson(row) : null;
  }

  Future<SubscriptionModel?> getActiveSubscriptionByOrg(String orgId) async {
    final companies = await SupabaseService.client
        .from('companies')
        .select('id')
        .eq('org_id', orgId)
        .eq('is_active', true);

    if ((companies as List).isEmpty) return null;

    final companyIds = companies.map((c) => c['id'] as String).toList();
    final row = await SupabaseService.client
        .from('subscriptions')
        .select()
        .inFilter('company_id', companyIds)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return row != null ? SubscriptionModel.fromJson(row) : null;
  }

  Future<String?> getOrgId(String companyId) async {
    final row = await SupabaseService.client
        .from('companies')
        .select('org_id')
        .eq('id', companyId)
        .maybeSingle();
    return row?['org_id'] as String?;
  }

  Future<List<Map<String, dynamic>>> getPlans() async {
    return (await SupabaseService.client
            .from('subscription_plans')
            .select()
            .order('monthly_price'))
        .cast<Map<String, dynamic>>();
  }

  Future<SubscriptionModel> createSubscription(
    Map<String, dynamic> data,
  ) async {
    final row = await SupabaseService.insert('subscriptions', data);
    return SubscriptionModel.fromJson(row);
  }

  Future<SubscriptionModel> updateSubscription(
    String id,
    Map<String, dynamic> data,
  ) async {
    final row = await SupabaseService.update('subscriptions', id, data);
    return SubscriptionModel.fromJson(row);
  }

  Future<Map<String, dynamic>> recordPayment(Map<String, dynamic> data) async {
    return await SupabaseService.insert('payments', data);
  }
}
