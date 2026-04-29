class CompanyModel {
  final String id;
  final String name;
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
  final DateTime createdAt;

  CompanyModel({
    required this.id,
    required this.name,
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
    required this.createdAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) => CompanyModel(
    id: json['id'],
    name: json['name'],
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
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
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
  };

  CompanyModel copyWith({
    String? name,
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
  }) => CompanyModel(
    id: id,
    createdAt: createdAt,
    name: name ?? this.name,
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
  );
}
