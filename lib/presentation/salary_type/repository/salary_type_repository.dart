import 'package:sri_hr/data/models/salary_type_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';

class SalaryTypeRepository {
  Future<List<SalaryTypeModel>> getSalaryTypes(String companyId) async {
    final rows = await SupabaseService.client
        .from('salary_types')
        .select()
        .eq('company_id', companyId)
        .order('name');
    return rows
        .map<SalaryTypeModel>((r) => SalaryTypeModel.fromJson(r))
        .toList();
  }

  Future<SalaryTypeModel> create(Map<String, dynamic> data) async {
    final row = await SupabaseService.insert('salary_types', data);
    return SalaryTypeModel.fromJson(row);
  }

  Future<SalaryTypeModel> update(String id, Map<String, dynamic> data) async {
    final row = await SupabaseService.update('salary_types', id, data);
    return SalaryTypeModel.fromJson(row);
  }

  Future<void> delete(String id) => SupabaseService.delete('salary_types', id);
}
