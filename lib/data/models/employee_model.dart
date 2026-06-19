import 'package:sri_hr/data/models/department_model.dart';
import 'package:sri_hr/data/models/role_model.dart';

enum Gender { male, female, other }

class EmployeeModel {
  final String id;
  final String companyId;
  final String? userId;
  final String? departmentId;
  final String? roleId;
  final String? statusId;
  final String? salaryTypeId;
  final String employeeCode; // non-nullable but fromJson uses ?? ''
  final String fullName; // non-nullable but fromJson uses ?? ''
  final DateTime? doj;
  final DateTime? dob;
  final Gender? gender;
  final String? mobile;
  final String? fatherHusbandName;
  final String? address;
  final String? aadharAddress;
  final String? country;
  final String? state;
  final String? city;
  final String? pincode;
  final String? email;
  final String? profilePicture;
  final String? profileTemplate;
  final String? aadharDocUrl;
  final String? otherDocUrl;
  final int casualLeave;
  final bool mobileLogin;
  final bool outsideOffice;
  final bool isActive;

  // Work shift overrides (employee-level, overrides company shift)
  final String? workStartTime;
  final String? workEndTime;
  final String? lunchStartTime;
  final String? lunchEndTime;

  // Joined
  final DepartmentModel? department;
  final RoleModel? role;

  EmployeeModel({
    required this.id,
    required this.companyId,
    this.userId,
    this.departmentId,
    this.roleId,
    this.statusId,
    this.salaryTypeId,
    required this.employeeCode,
    required this.fullName,
    this.doj,
    this.dob,
    this.gender,
    this.mobile,
    this.fatherHusbandName,
    this.address,
    this.aadharAddress,
    this.country,
    this.state,
    this.city,
    this.pincode,
    this.email,
    this.profilePicture,
    this.aadharDocUrl,
    this.otherDocUrl,
    this.casualLeave = 12,
    this.mobileLogin = true,
    this.outsideOffice = false,
    this.isActive = true,
    this.workStartTime,
    this.workEndTime,
    this.lunchStartTime,
    this.lunchEndTime,
    this.profileTemplate,
    this.department,
    this.role,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> j) => EmployeeModel(
    id: (j['id'] as String?) ?? '',
    companyId: (j['company_id'] as String?) ?? '',
    userId: j['user_id'] as String?,
    departmentId: j['department_id'] as String?,
    roleId: j['role_id'] as String?,
    statusId: j['status_id'] as String?,
    salaryTypeId: j['salary_type_id'] as String?,
    employeeCode: (j['employee_code'] as String?) ?? '',
    fullName: (j['full_name'] as String?) ?? '',
    doj: j['doj'] != null ? DateTime.tryParse(j['doj'] as String) : null,
    dob: j['dob'] != null ? DateTime.tryParse(j['dob'] as String) : null,
    gender: j['gender'] != null
        ? Gender.values.firstWhere(
            (e) => e.name == (j['gender'] as String),
            orElse: () => Gender.male,
          )
        : null,
    mobile: j['mobile'] as String?,
    fatherHusbandName: j['father_husband_name'] as String?,
    address: j['address'] as String?,
    aadharAddress: j['aadhar_address'] as String?,
    country: j['country'] as String?,
    state: j['state'] as String?,
    city: j['city'] as String?,
    pincode: j['pincode'] as String?,
    email: j['email'] as String?,
    profilePicture: j['profile_picture'] as String?,
    profileTemplate: j['face_template'] as String?,
    aadharDocUrl: j['aadhar_doc_url'] as String?,
    otherDocUrl: j['other_doc_url'] as String?,
    casualLeave: (j['casual_leave'] as int?) ?? 12,
    mobileLogin: (j['mobile_login'] as bool?) ?? true,
    outsideOffice: (j['outside_office'] as bool?) ?? false,
    isActive: (j['is_active'] as bool?) ?? true,
    workStartTime: j['work_start_time'] as String?,
    workEndTime: j['work_end_time'] as String?,
    lunchStartTime: j['lunch_start_time'] as String?,
    lunchEndTime: j['lunch_end_time'] as String?,
    department: j['departments'] != null
        ? DepartmentModel.fromJson(j['departments'] as Map<String, dynamic>)
        : null,
    role: j['roles'] != null
        ? RoleModel.fromJson(j['roles'] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'company_id': companyId,
    'user_id': userId,
    'department_id': departmentId,
    'role_id': roleId,
    'status_id': statusId,
    'salary_type_id': salaryTypeId,
    'employee_code': employeeCode,
    'full_name': fullName,
    'doj': doj?.toIso8601String().substring(0, 10),
    'dob': dob?.toIso8601String().substring(0, 10),
    'gender': gender?.name,
    'mobile': mobile,
    'father_husband_name': fatherHusbandName,
    'address': address,
    'aadhar_address': aadharAddress,
    'country': country,
    'state': state,
    'city': city,
    'pincode': pincode,
    'email': email,
    'profile_picture': profilePicture,
    'face_template': profileTemplate,
    'aadhar_doc_url': aadharDocUrl,
    'other_doc_url': otherDocUrl,
    'casual_leave': casualLeave,
    'mobile_login': mobileLogin,
    'outside_office': outsideOffice,
    'is_active': isActive,
    'work_start_time': workStartTime,
    'work_end_time': workEndTime,
    'lunch_start_time': lunchStartTime,
    'lunch_end_time': lunchEndTime,
  };
}