import 'package:sri_hr/data/models/role_model.dart';
import 'package:sri_hr/data/models/role_permission_model.dart';
import 'package:sri_hr/data/services/supabase_service.dart';

class RoleRepository {
  Future<List<RoleModel>> getRoles(String companyId) async {
    final rows = await SupabaseService.client
        .from('roles')
        .select()
        .eq('company_id', companyId)
        .order('name');
    return rows.map<RoleModel>((r) => RoleModel.fromJson(r)).toList();
  }

  Future<RoleModel> createRole(Map<String, dynamic> data) async {
    final row = await SupabaseService.insert('roles', data);
    return RoleModel.fromJson(row);
  }

  Future<RoleModel> updateRole(String id, Map<String, dynamic> data) async {
    final row = await SupabaseService.update('roles', id, data);
    return RoleModel.fromJson(row);
  }

  Future<void> deleteRole(String id) => SupabaseService.delete('roles', id);

  Future<List<RolePermissionModel>> getPermissions(String roleId) async {
    final rows = await SupabaseService.client
        .from('role_permissions')
        .select()
        .eq('role_id', roleId);
    return rows
        .map<RolePermissionModel>((r) => RolePermissionModel.fromJson(r))
        .toList();
  }

  Future<void> savePermissions(
    String companyId,
    String roleId,
    List<RolePermissionModel> permissions,
  ) async {
    for (final p in permissions) {
      // Upsert by role_id + module
      await SupabaseService.client.from('role_permissions').upsert({
        'company_id': companyId,
        'role_id': roleId,
        'module': p.module,
        'can_view': p.canView,
        'can_add': p.canAdd,
        'can_edit': p.canEdit,
        'can_delete': p.canDelete,
      }, onConflict: 'role_id,module');
    }
  }
}
