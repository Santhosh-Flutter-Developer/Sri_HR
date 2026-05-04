import 'package:sri_hr/data/models/role_permission_model.dart';

class RoleModel {
  final String id;
  final String companyId;
  final String name;
  final String workingFrom;
  final String workingTo;
  final int breakMinutes;
  final int permissionMinutes;
  final int casualLeave;
  final bool isAdmin;
  final List<RolePermissionModel> permissions;

  RoleModel({
    required this.id,
    required this.companyId,
    required this.name,
    this.workingFrom = '09:00',
    this.workingTo = '18:00',
    this.breakMinutes = 30,
    this.permissionMinutes = 60,
    this.casualLeave = 12,
    this.isAdmin = false,
    this.permissions = const [],
  });

  factory RoleModel.fromJson(Map<String, dynamic> j) => RoleModel(
    id: (j['id'] as String?) ?? '',
    companyId: (j['company_id'] as String?) ?? '',
    name: (j['name'] as String?) ?? '',
    workingFrom: (j['working_from'] as String?) ?? '09:00',
    workingTo: (j['working_to'] as String?) ?? '18:00',
    breakMinutes: (j['break_minutes'] as int?) ?? 30,
    permissionMinutes: (j['permission_minutes'] as int?) ?? 60,
    casualLeave: (j['casual_leave'] as int?) ?? 12,
    isAdmin: (j['is_admin'] as bool?) ?? false,
  );

  Map<String, dynamic> toJson() => {
    'company_id': companyId,
    'name': name,
    'working_from': workingFrom,
    'working_to': workingTo,
    'break_minutes': breakMinutes,
    'permission_minutes': permissionMinutes,
    'casual_leave': casualLeave,
    'is_admin': isAdmin,
  };
}
