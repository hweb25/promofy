import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme.dart';
import '../models/promotion.dart';

class PromotionCard extends StatelessWidget {
  final Promotion promotion;
  final VoidCallback onTap;
  /// When true, renders a compact horizontal-scroll variant.
  final bool compact;

  const PromotionCard({
    super.key,
    required this.promotion,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return compact ? _CompactCard(promotion: promotion, onTap: onTap) : _FullCard(promotion: promotion, onTap: onTap);
  }
}

// ── Full vertical card ────────────────────────────────────────────────────────
class _FullCard extends StatelessWidget {
  final Promotion promotion;
  final VoidCallback onTap;

  const _FullCard({required this.promotion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.categoryColor(promotion.businessCategory ?? '');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner / Image ─────────────────────────────────────────────
            SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background – image or gradient
                  if (promotion.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: promotion.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Shimmer.fromColors(
                        baseColor: const Color(0xFFE8E4F7),
                        highlightColor: Colors.white,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (_, __, ___) => _GradientBanner(color: color),
                    )
                  else
                    _GradientBanner(color: color),

                  // Dark scrim for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.55),
                        ],
                        stops: const [0.3, 1.0],
                      ),
                    ),
                  ),

                  // Discount badge – top-left
                  Positioned(
                    top: 12,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentColor.withOpacity(0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        promotion.discountLabel,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  // Distance badge – top-right
                  if (promotion.distanceMeters != null)
                    Positioned(
                      top: 12,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 11, color: Colors.white70),
                            const SizedBox(width: 3),
                            Text(
                              promotion.formattedDistance,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Timer badge
                  Positioned(
                    bottom: 10,
                    right: 14,
                    child: _TimerBadge(endsAt: promotion.endsAt),
                  ),
                ],
              ),
            ),

            // ── Card Body ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Row(
                children: [
                  // Business logo placeholder
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withOpacity(0.2), width: 1.5),
                    ),
                    child: Icon(
                      AppTheme.categoryIcon(promotion.businessCategory ?? ''),
                      size: 20,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Business name + category + title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promotion.title,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              promotion.businessName ?? 'Local Business',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            if (promotion.businessCategory != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  color: AppTheme.textLight,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                promotion.businessCategory!,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compact card (horizontal scroll) ─────────────────────────────────────────
class _CompactCard extends StatelessWidget {
  final Promotion promotion;
  final VoidCallback onTap;

  const _CompactCard({required this.promotion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.categoryColor(promotion.businessCategory ?? '');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppTheme.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (promotion.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: promotion.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Shimmer.fromColors(
                        baseColor: const Color(0xFFE8E4F7),
                        highlightColor: Colors.white,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (_, __, ___) => _GradientBanner(color: color),
                    )
                  else
                    _GradientBanner(color: color),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),

                  // Discount badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        promotion.discountLabel,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promotion.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    promotion.businessName ?? 'Local Business',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (promotion.distanceMeters != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 11, color: AppTheme.primaryColor),
                        const SizedBox(width: 3),
                        Text(
                          promotion.formattedDistance,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gradient banner fallback ──────────────────────────────────────────────────
class _GradientBanner extends StatelessWidget {
  final Color color;
  const _GradientBanner({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.6)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.storefront_rounded,
          size: 42,
          color: Colors.white.withOpacity(0.35),
        ),
      ),
    );
  }
}

// ── Timer badge ───────────────────────────────────────────────────────────────
class _TimerBadge extends StatefulWidget {
  final DateTime endsAt;
  const _TimerBadge({required this.endsAt});

  @override
  State<_TimerBadge> createState() => _TimerBadgeState();
}

class _TimerBadgeState extends State<_TimerBadge> {
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
  }

  void _updateRemaining() {
    final now = DateTime.now();
    _remaining = widget.endsAt.difference(now);
  }

  String get _label {
    if (_remaining.isNegative) return 'Expired';
    if (_remaining.inDays >= 1) return '${_remaining.inDays}d left';
    if (_remaining.inHours >= 1) return '${_remaining.inHours}h left';
    return '${_remaining.inMinutes}m left';
  }

  bool get _isUrgent => !_remaining.isNegative && _remaining.inHours < 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isUrgent
            ? AppTheme.accentColor.withOpacity(0.9)
            : Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isUrgent ? Icons.local_fire_department_rounded : Icons.access_time_rounded,
            size: 10,
            color: Colors.white,
          ),
          const SizedBox(width: 3),
          Text(
            _label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
