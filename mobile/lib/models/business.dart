class Business {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String category;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? phone;
  final String? email;
  final String addressLine1;
  final String city;
  final String country;
  final double latitude;
  final double longitude;
  final Map<String, dynamic> operatingHours;
  final String subscriptionTier;
  final int geofenceRadiusMeters;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;

  Business({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    required this.category,
    this.logoUrl,
    this.coverImageUrl,
    this.phone,
    this.email,
    required this.addressLine1,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.operatingHours = const {},
    this.subscriptionTier = 'free',
    this.geofenceRadiusMeters = 100,
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'],
      ownerId: json['owner_id'],
      name: json['name'],
      description: json['description'],
      category: json['category'] ?? 'restaurant',
      logoUrl: json['logo_url'],
      coverImageUrl: json['cover_image_url'],
      phone: json['phone'],
      email: json['email'],
      addressLine1: json['address_line1'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? 'CO',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      operatingHours: json['operating_hours'] ?? {},
      subscriptionTier: json['subscription_tier'] ?? 'free',
      geofenceRadiusMeters: json['geofence_radius_meters'] ?? 100,
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'owner_id': ownerId,
    'name': name,
    'description': description,
    'category': category,
    'logo_url': logoUrl,
    'cover_image_url': coverImageUrl,
    'phone': phone,
    'email': email,
    'address_line1': addressLine1,
    'city': city,
    'country': country,
    'location': 'POINT($longitude $latitude)',
    'operating_hours': operatingHours,
    'subscription_tier': subscriptionTier,
    'geofence_radius_meters': geofenceRadiusMeters,
  };
}
