class RolePermissionModel {
  final String id;
  final String companyId;
  final String roleId;
  final String module;
  final bool canView;
  final bool canAdd;
  final bool canEdit;
  final bool canDelete;

  RolePermissionModel({
    required this.id,
    required this.companyId,
    required this.roleId,
    required this.module,
    this.canView = false,
    this.canAdd = false,
    this.canEdit = false,
    this.canDelete = false,
  });

  factory RolePermissionModel.fromJson(Map<String, dynamic> j) =>
      RolePermissionModel(
        id: j['id'],
        companyId: j['company_id'],
        roleId: j['role_id'],
        module: j['module'],
        canView: j['can_view'] ?? false,
        canAdd: j['can_add'] ?? false,
        canEdit: j['can_edit'] ?? false,
        canDelete: j['can_delete'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'role_id': roleId,
        'module': module,
        'can_view': canView,
        'can_add': canAdd,
        'can_edit': canEdit,
        'can_delete': canDelete,
      };

  RolePermissionModel copyWith({
    bool? canView, bool? canAdd, bool? canEdit, bool? canDelete,
  }) => RolePermissionModel(
    id: id, companyId: companyId, roleId: roleId, module: module,
    canView: canView ?? this.canView, canAdd: canAdd ?? this.canAdd,
    canEdit: canEdit ?? this.canEdit, canDelete: canDelete ?? this.canDelete,
  );
}