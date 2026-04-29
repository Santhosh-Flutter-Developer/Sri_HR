import 'package:sri_hr/data/models/department_model.dart';
import 'package:sri_hr/data/models/role_model.dart';

enum Gender { male, female, other }

class EmployeeModel {
  final String id;
  final String companyId;
  final String? userId;
  final String departmentId;
  final String roleId;
  final String? statusId;
  final String? salaryTypeId;
  final String employeeCode;
  final String fullName;
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
  final String? aadharDocUrl;
  final String? otherDocUrl;
  final String? password;
  final int casualLeave;
  final bool mobileLogin;
  final bool outsideOffice;
  final bool isActive;

  // Joined
  final DepartmentModel? department;
  final RoleModel? role;

  EmployeeModel({
    required this.id,
    required this.companyId,
    this.userId,
    required this.departmentId,
    required this.roleId,
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
    this.password,
    this.profilePicture,
    this.aadharDocUrl,
    this.otherDocUrl,
    this.casualLeave = 12,
    this.mobileLogin = true,
    this.outsideOffice = false,
    this.isActive = true,
    this.department,
    this.role,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> j) => EmployeeModel(
        id: j['id'],
        companyId: j['company_id'],
        userId: j['user_id'],
        departmentId: j['department_id'],
        roleId: j['role_id'],
        statusId: j['status_id'],
        salaryTypeId: j['salary_type_id'],
        employeeCode: j['employee_code'],
        fullName: j['full_name'],
        doj: j['doj'] != null ? DateTime.parse(j['doj']) : null,
        dob: j['dob'] != null ? DateTime.parse(j['dob']) : null,
        gender: j['gender'] != null
            ? Gender.values.firstWhere((e) => e.name == j['gender'].toString().toLowerCase(),
                orElse: () => Gender.male)
            : null,
        mobile: j['mobile'],
        fatherHusbandName: j['father_husband_name'],
        address: j['address'],
        aadharAddress: j['aadhar_address'],
        country: j['country'],
        state: j['state'],
        city: j['city'],
        pincode: j['pincode'],
        email: j['email'],
        profilePicture: j['profile_picture'],
        aadharDocUrl: j['aadhar_doc_url'],
        otherDocUrl: j['other_doc_url'],
        password: j['password'],
        casualLeave: j['casual_leave'] ?? 12,
        mobileLogin: j['mobile_login'] ?? true,
        outsideOffice: j['outside_office'] ?? false,
        isActive: j['is_active'] ?? true,
        department: j['departments'] != null
            ? DepartmentModel.fromJson(j['departments'])
            : null,
        role: j['roles'] != null ? RoleModel.fromJson(j['roles']) : null,
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
        'password': password,
        'profile_picture': profilePicture,
        'aadhar_doc_url': aadharDocUrl,
        'other_doc_url': otherDocUrl,
        'casual_leave': casualLeave,
        'mobile_login': mobileLogin,
        'outside_office': outsideOffice,
        'is_active': isActive,
      };
}
