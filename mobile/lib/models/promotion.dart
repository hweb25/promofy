class Promotion {
  final String id;
  final String businessId;
  final String title;
  final String description;
  final String? imageUrl;
  final String? discountType;
  final double? discountValue;
  final double? originalPrice;
  final String status;
  final DateTime startsAt;
  final DateTime endsAt;
  final List<String> activeDays;
  final String? activeTimeStart;
  final String? activeTimeEnd;
  final int? maxTotalRedemptions;
  final int maxPerUser;
  final int currentRedemptions;

  // Joined fields from business
  final String? businessName;
  final String? businessLogo;
  final String? businessCategory;
  final double? latitude;
  final double? longitude;
  final double? distanceMeters;
  final int? geofenceRadius;

  Promotion({
    required this.id,
    required this.businessId,
    required this.title,
    required this.description,
    this.imageUrl,
    this.discountType,
    this.discountValue,
    this.originalPrice,
    this.status = 'draft',
    required this.startsAt,
    required this.endsAt,
    this.activeDays = const ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
    this.activeTimeStart,
    this.activeTimeEnd,
    this.maxTotalRedemptions,
    this.maxPerUser = 1,
    this.currentRedemptions = 0,
    this.businessName,
    this.businessLogo,
    this.businessCategory,
    this.latitude,
    this.longitude,
    this.distanceMeters,
    this.geofenceRadius,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['promotion_id'] ?? json['id'],
      businessId: json['business_id'] ?? '',
      title: json['title'],
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
      discountType: json['discount_type'],
      discountValue: (json['discount_value'] as num?)?.toDouble(),
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      status: json['status'] ?? 'active',
      startsAt: DateTime.parse(json['starts_at']),
      endsAt: DateTime.parse(json['ends_at']),
      activeDays: (json['active_days'] as List?)?.cast<String>() ?? [],
      activeTimeStart: json['active_time_start'],
      activeTimeEnd: json['active_time_end'],
      maxTotalRedemptions: json['max_total_redemptions'],
      maxPerUser: json['max_per_user'] ?? 1,
      currentRedemptions: json['current_redemptions'] ?? 0,
      businessName: json['business_name'],
      businessLogo: json['business_logo'],
      businessCategory: json['business_category'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      geofenceRadius: json['geofence_radius'],
    );
  }

  Map<String, dynamic> toJson() => {
    'business_id': businessId,
    'title': title,
    'description': description,
    'image_url': imageUrl,
    'discount_type': discountType,
    'discount_value': discountValue,
    'original_price': originalPrice,
    'status': status,
    'starts_at': startsAt.toIso8601String(),
    'ends_at': endsAt.toIso8601String(),
    'active_days': activeDays,
    'active_time_start': activeTimeStart,
    'active_time_end': activeTimeEnd,
    'max_total_redemptions': maxTotalRedemptions,
    'max_per_user': maxPerUser,
  };

  String get formattedDistance {
    if (distanceMeters == null) return '';
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()}m';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)}km';
  }

  String get discountLabel {
    if (discountType == 'percentage') return '${discountValue?.round()}% OFF';
    if (discountType == 'bogo') return '2x1';
    if (discountType == 'fixed') return '\$${discountValue?.round()} OFF';
    if (discountType == 'free_item') return 'FREE';
    return title;
  }

  bool get isCurrentlyActive {
    final now = DateTime.now();
    return status == 'active' && now.isAfter(startsAt) && now.isBefore(endsAt);
  }

  // ── Value & scarcity helpers ────────────────────────────────────────────────
  // Centralized so savings/scarcity read identically on every screen.

  static String _money(double v) =>
      v == v.roundToDouble() ? '\$${v.round()}' : '\$${v.toStringAsFixed(2)}';

  /// The post-discount price, when an [originalPrice] and a computable discount
  /// are available. Null for discount types we can't price (e.g. bogo).
  double? get discountedPrice {
    final orig = originalPrice;
    if (orig == null) return null;
    switch (discountType) {
      case 'percentage':
        if (discountValue == null) return null;
        return orig * (1 - discountValue! / 100);
      case 'fixed':
        if (discountValue == null) return null;
        final d = orig - discountValue!;
        return d < 0 ? 0 : d;
      case 'free_item':
        return 0;
      default:
        return null;
    }
  }

  /// Absolute amount saved versus [originalPrice], if computable and positive.
  double? get savedAmount {
    final orig = originalPrice;
    final disc = discountedPrice;
    if (orig == null || disc == null) return null;
    final saved = orig - disc;
    return saved > 0 ? saved : null;
  }

  String? get originalPriceLabel =>
      originalPrice == null ? null : _money(originalPrice!);

  String? get discountedPriceLabel {
    final d = discountedPrice;
    return d == null ? null : _money(d);
  }

  String? get savedAmountLabel {
    final s = savedAmount;
    return s == null ? null : _money(s);
  }

  /// Redemptions still available, when a total cap is set.
  int? get remainingRedemptions => maxTotalRedemptions == null
      ? null
      : (maxTotalRedemptions! - currentRedemptions);

  /// True when stock is scarce enough to warrant an urgency nudge.
  bool get isLowStock {
    final r = remainingRedemptions;
    if (r == null) return false;
    return r > 0 &&
        (r <= 10 ||
            (maxTotalRedemptions! > 0 && r / maxTotalRedemptions! <= 0.2));
  }
}
