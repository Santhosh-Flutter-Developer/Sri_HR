class DepartmentModel {
  final String id;
  final String companyId;
  final String code;
  final String name;
  final bool mobileLogin;
  final bool outsideAttendance;

  DepartmentModel({
    required this.id,
    required this.companyId,
    required this.code,
    required this.name,
    this.mobileLogin = true,
    this.outsideAttendance = false,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> j) => DepartmentModel(
    id: j['id'],
    companyId: j['company_id'],
    code: j['code'],
    name: j['name'],
    mobileLogin: j['mobile_login'] ?? true,
    outsideAttendance: j['outside_attendance'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'company_id': companyId,
    'code': code,
    'name': name,
    'mobile_login': mobileLogin,
    'outside_attendance': outsideAttendance,
  };
}
