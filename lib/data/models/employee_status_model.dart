class EmployeeStatusModel {
  final String id;
  final String companyId;
  final String name;

  EmployeeStatusModel({
    required this.id,
    required this.companyId,
    required this.name,
  });

  factory EmployeeStatusModel.fromJson(Map<String, dynamic> j) =>
      EmployeeStatusModel(
        id: j['id'],
        companyId: j['company_id'],
        name: j['name'],
      );

  Map<String, dynamic> toJson() => {'company_id': companyId, 'name': name};
}
