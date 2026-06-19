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

  /// Returns the active subscription for an entire organisation.
  /// The subscription is looked up via the HQ/root company (the one that
  /// purchased the plan — identified by org_id on the companies table).
  /// Falls back to a per-branch lookup if no org-level sub exists.
  Future<SubscriptionModel?> getActiveSubscriptionByOrg(String orgId) async {
    // Find the primary (HQ) company for this org — the one whose subscription
    // was purchased. We look for the most recently created active subscription
    // among all branches in this org.
    final companies = await SupabaseService.client
        .from('companies')
        .select('id')
        .eq('org_id', orgId)
        .eq('is_active', true);

    if ((companies as List).isEmpty) return null;

    final companyIds = companies.map((c) => c['id'] as String).toList();

    // Pick the most recent active subscription across all branches in this org
    final row = await SupabaseService.client
        .from('subscriptions')
        .select()
        .inFilter('company_id', companyIds)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return row != null ? SubscriptionModel.fromJson(row) : null;
  }

  /// Returns the org_id for a given company.
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