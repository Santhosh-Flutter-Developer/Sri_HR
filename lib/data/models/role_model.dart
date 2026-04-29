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
    id: j['id'],
    companyId: j['company_id'],
    name: j['name'],
    workingFrom: j['working_from'] ?? '09:00',
    workingTo: j['working_to'] ?? '18:00',
    breakMinutes: j['break_minutes'] ?? 30,
    permissionMinutes: j['permission_minutes'] ?? 60,
    casualLeave: j['casual_leave'] ?? 12,
    isAdmin: j['is_admin'] ?? false,
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
