class SalaryTypeModel {
  final String id;
  final String companyId;
  final String name;

  SalaryTypeModel({
    required this.id,
    required this.companyId,
    required this.name,
  });

  factory SalaryTypeModel.fromJson(Map<String, dynamic> j) => SalaryTypeModel(
    id: (j['id'] as String?) ?? '',
    companyId: (j['company_id'] as String?) ?? '',
    name: (j['name'] as String?) ?? '',
  );

  Map<String, dynamic> toJson() => {'company_id': companyId, 'name': name};
}
