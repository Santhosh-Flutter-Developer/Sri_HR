// lib/data/models/company_model.dart
class CompanyModel {
  final String id;
  final String name;
  final String? orgId;
  final String? branchCode;
  final String? logoUrl;
  final String? gstin;
  final String? phone;
  final String? email;
  final String? address;
  final String? country;
  final String? state;
  final String? city;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final int radius;
  final bool isActive;
  final DateTime createdAt;

  CompanyModel({
    required this.id,
    required this.name,
    this.orgId,
    this.branchCode,
    this.logoUrl,
    this.gstin,
    this.phone,
    this.email,
    this.address,
    this.country,
    this.state,
    this.city,
    this.pincode,
    this.latitude,
    this.longitude,
    this.radius = 100,
    this.isActive = true,
    required this.createdAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) => CompanyModel(
    id: json['id'],
    name: json['name'],
    orgId: json['org_id'],
    branchCode: json['branch_code'],
    logoUrl: json['logo_url'],
    gstin: json['gstin'],
    phone: json['phone'],
    email: json['email'],
    address: json['address'],
    country: json['country'],
    state: json['state'],
    city: json['city'],
    pincode: json['pincode'],
    latitude: json['latitude']?.toDouble(),
    longitude: json['longitude']?.toDouble(),
    radius: json['radius'] ?? 100,
    isActive: json['is_active'] ?? true,
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'org_id': orgId,
    'branch_code': branchCode,
    'logo_url': logoUrl,
    'gstin': gstin,
    'phone': phone,
    'email': email,
    'address': address,
    'country': country,
    'state': state,
    'city': city,
    'pincode': pincode,
    'latitude': latitude,
    'longitude': longitude,
    'radius': radius,
    'is_active': isActive,
  };

  CompanyModel copyWith({
    String? name,
    String? orgId,
    String? branchCode,
    String? logoUrl,
    String? gstin,
    String? phone,
    String? email,
    String? address,
    String? country,
    String? state,
    String? city,
    String? pincode,
    double? latitude,
    double? longitude,
    int? radius,
    bool? isActive,
  }) => CompanyModel(
    id: id,
    createdAt: createdAt,
    name: name ?? this.name,
    orgId: orgId ?? this.orgId,
    branchCode: branchCode ?? this.branchCode,
    logoUrl: logoUrl ?? this.logoUrl,
    gstin: gstin ?? this.gstin,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    address: address ?? this.address,
    country: country ?? this.country,
    state: state ?? this.state,
    city: city ?? this.city,
    pincode: pincode ?? this.pincode,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    radius: radius ?? this.radius,
    isActive: isActive ?? this.isActive,
  );
}
