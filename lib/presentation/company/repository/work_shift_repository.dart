import 'package:sri_hr/data/models/work_shift_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';

class WorkShiftRepository {
  /// Fetch shift for a company (returns null if not set)
  Future<WorkShiftModel?> getShift(String companyId) async {
    final rows = await SupabaseService.client
        .from('work_shifts')
        .select()
        .eq('company_id', companyId)
        .limit(1);
    if ((rows as List).isEmpty) return null;
    return WorkShiftModel.fromJson(rows.first as Map<String, dynamic>);
  }

  /// Upsert (insert or update) the shift for a company
  Future<WorkShiftModel> upsertShift(WorkShiftModel shift) async {
    // Try update first; if no rows affected, insert
    final existing = await getShift(shift.companyId);
    if (existing != null) {
      final row = await SupabaseService.client
          .from('work_shifts')
          .update(shift.toJson())
          .eq('id', existing.id)
          .select()
          .single();
      return WorkShiftModel.fromJson(row);
    } else {
      final row = await SupabaseService.client
          .from('work_shifts')
          .insert(shift.toJson())
          .select()
          .single();
      return WorkShiftModel.fromJson(row);
    }
  }
}