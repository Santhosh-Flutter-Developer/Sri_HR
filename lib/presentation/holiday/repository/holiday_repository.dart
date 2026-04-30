import 'package:sri_hr/data/models/holiday_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';

class HolidayRepository {
  Future<List<HolidayModel>> getHolidays(String companyId, {int? year}) async {
    var query = SupabaseService.client
        .from('holidays')
        .select()
        .eq('company_id', companyId);
    if (year != null) {
      query = query
          .gte('date', '$year-01-01')
          .lte('date', '$year-12-31');
    }
    final rows = await query.order('date');
    return rows.map<HolidayModel>((r) => HolidayModel.fromJson(r)).toList();
  }

  Future<bool> isHoliday(String companyId, DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final row = await SupabaseService.client
        .from('holidays')
        .select()
        .eq('company_id', companyId)
        .eq('date', dateStr)
        .maybeSingle();
    return row != null;
  }

  Future<HolidayModel> createHoliday(Map<String, dynamic> data) async {
    final row = await SupabaseService.insert('holidays', data);
    return HolidayModel.fromJson(row);
  }

  Future<HolidayModel> updateHoliday(String id, Map<String, dynamic> data) async {
    final row = await SupabaseService.update('holidays', id, data);
    return HolidayModel.fromJson(row);
  }

  Future<void> deleteHoliday(String id) => SupabaseService.delete('holidays', id);
}