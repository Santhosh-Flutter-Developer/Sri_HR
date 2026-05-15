import 'package:sri_hr/data/utils/network_time.dart';

class UserModel {
  final String id;
  final String companyId;
  final String? roleId;
  final String? employeeId;
  final String fullName;
  final String? email;
  final String? username;
  final String? phone;
  final bool isActive;
  final bool isAdmin;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.companyId,
    this.roleId,
    this.employeeId,
    required this.fullName,
    this.email,
    this.username,
    this.phone,
    this.isActive = true,
    this.isAdmin = false,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: (j['id'] as String?) ?? '',
    companyId: (j['company_id'] as String?) ?? '',
    roleId: j['role_id'] as String?,
    employeeId: j['employee_id'] as String?,
    fullName: (j['full_name'] as String?) ?? '',
    email: j['email'] as String?,
    username: j['username'] as String?,
    phone: j['phone'] as String?,
    isActive: (j['is_active'] as bool?) ?? true,
    isAdmin: (j['is_admin'] as bool?) ?? false,
    createdAt:
        DateTime.tryParse(j['created_at'] as String? ?? '') ?? NetworkTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'company_id': companyId,
    'role_id': roleId,
    'employee_id': employeeId,
    'full_name': fullName,
    'email': email,
    'username': username,
    'phone': phone,
    'is_active': isActive,
    'is_admin': isAdmin,
  };
}
