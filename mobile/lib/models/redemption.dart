class Redemption {
  final String id;
  final String promotionId;
  final String consumerId;
  final String businessId;
  final String redemptionCode;
  final String qrData;
  final String status;
  final DateTime claimedAt;
  final DateTime? redeemedAt;
  final DateTime expiresAt;

  Redemption({
    required this.id,
    required this.promotionId,
    required this.consumerId,
    required this.businessId,
    required this.redemptionCode,
    required this.qrData,
    this.status = 'claimed',
    required this.claimedAt,
    this.redeemedAt,
    required this.expiresAt,
  });

  factory Redemption.fromJson(Map<String, dynamic> json) {
    return Redemption(
      id: json['id'],
      promotionId: json['promotion_id'],
      consumerId: json['consumer_id'],
      businessId: json['business_id'],
      redemptionCode: json['redemption_code'] ?? json['code'] ?? '',
      qrData: json['qr_data'] ?? '',
      status: json['status'] ?? 'claimed',
      claimedAt: DateTime.parse(json['claimed_at'] ?? json['created_at']),
      redeemedAt: json['redeemed_at'] != null ? DateTime.parse(json['redeemed_at']) : null,
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isRedeemed => status == 'redeemed';
  bool get canRedeem => status == 'claimed' && !isExpired;

  Duration get timeRemaining => expiresAt.difference(DateTime.now());
}
