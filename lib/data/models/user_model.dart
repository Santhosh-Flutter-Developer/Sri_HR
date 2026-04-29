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
    id: j['id'],
    companyId: j['company_id'],
    roleId: j['role_id'],
    employeeId: j['employee_id'],
    fullName: j['full_name'] ?? '',
    email: j['email'],
    username: j['username'],
    phone: j['phone'],
    isActive: j['is_active'] ?? true,
    isAdmin: j['is_admin'] ?? false,
    createdAt: DateTime.parse(j['created_at']),
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
