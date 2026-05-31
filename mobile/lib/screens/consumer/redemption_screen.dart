import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../services/supabase_service.dart';

class RedemptionScreen extends ConsumerStatefulWidget {
  final String redemptionId;
  const RedemptionScreen({super.key, required this.redemptionId});

  @override
  ConsumerState<RedemptionScreen> createState() => _RedemptionScreenState();
}

class _RedemptionScreenState extends ConsumerState<RedemptionScreen> {
  Map<String, dynamic>? _redemption;
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;
  bool _isRedeemed = false;
  bool _error = false;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _loadRedemption();
  }

  Future<void> _loadRedemption() async {
    try {
      final data = await SupabaseService.client
          .from('redemptions')
          .select(
              '*, promotions(title, description, discount_type, discount_value, original_price), businesses(name)')
          .eq('id', widget.redemptionId)
          .single();

      if (!mounted) return;

      setState(() {
        _redemption = data;
        _isRedeemed = data['status'] == 'redeemed';
      });

      if (!_isRedeemed) {
        _startCountdown();
        _listenForRedemption();
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _startCountdown() {
    final expiresAt = DateTime.parse(_redemption!['expires_at']);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = expiresAt.difference(DateTime.now());
      if (remaining.isNegative) {
        _timer?.cancel();
        if (mounted) setState(() => _timeRemaining = Duration.zero);
      } else {
        if (mounted) setState(() => _timeRemaining = remaining);
      }
    });
    _timeRemaining = expiresAt.difference(DateTime.now());
  }

  void _listenForRedemption() {
    _sub = SupabaseService.client
        .from('redemptions')
        .stream(primaryKey: ['id'])
        .eq('id', widget.redemptionId)
        .listen((data) {
      if (data.isNotEmpty && data.first['status'] == 'redeemed' && mounted) {
        _onRedeemed();
      }
    });
  }

  void _onRedeemed() {
    if (_isRedeemed) return;
    _timer?.cancel();
    HapticFeedback.mediumImpact();
    setState(() => _isRedeemed = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  String _discountLabel(Map<String, dynamic>? promo) {
    if (promo == null) return 'Deal';
    final type = promo['discount_type'];
    final val = (promo['discount_value'] as num?)?.round();
    switch (type) {
      case 'percentage':
        return '$val% OFF';
      case 'bogo':
        return '2 × 1';
      case 'fixed':
        return '\$$val OFF';
      case 'free_item':
        return 'FREE';
      default:
        return promo['title']?.toString() ?? 'Deal';
    }
  }

  String? _savedLabel(Map<String, dynamic>? promo) {
    if (promo == null) return null;
    final orig = (promo['original_price'] as num?)?.toDouble();
    if (orig == null) return null;
    final type = promo['discount_type'];
    final val = (promo['discount_value'] as num?)?.toDouble();
    double? saved;
    switch (type) {
      case 'percentage':
        if (val != null) saved = orig * val / 100;
        break;
      case 'fixed':
        saved = val;
        break;
      case 'free_item':
        saved = orig;
        break;
    }
    if (saved == null || saved <= 0) return null;
    return saved == saved.roundToDouble()
        ? '\$${saved.round()}'
        : '\$${saved.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Your Offer'),
          backgroundColor: AppTheme.surfaceColor,
          foregroundColor: AppTheme.textPrimary,
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 52, color: AppTheme.textLight),
                  const SizedBox(height: 14),
                  Text("We couldn't load your code",
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Check your connection and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _error = false);
                        _loadRedemption();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Try again'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/consumer'),
                    child: const Text('Back to deals'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_redemption == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Your Offer'),
          backgroundColor: AppTheme.surfaceColor,
          foregroundColor: AppTheme.textPrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    final code = _redemption!['redemption_code']?.toString() ?? '';
    final promotion = _redemption!['promotions'] as Map<String, dynamic>?;
    final business = _redemption!['businesses'] as Map<String, dynamic>?;
    final isExpired = !_isRedeemed &&
        (_timeRemaining.isNegative || _timeRemaining == Duration.zero);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_isRedeemed ? 'Redeemed' : 'Your Offer'),
        backgroundColor:
            _isRedeemed ? AppTheme.successColor : AppTheme.surfaceColor,
        foregroundColor: _isRedeemed ? Colors.white : AppTheme.textPrimary,
      ),
      body: _isRedeemed
          ? _SuccessView(
              businessName: business?['name']?.toString() ?? 'the business',
              discountLabel: _discountLabel(promotion),
              promoTitle: promotion?['title']?.toString() ?? 'your deal',
              savedLabel: _savedLabel(promotion),
              onDone: () => context.go('/consumer'),
            )
          : _ActiveView(
              qrData: _redemption!['qr_data']?.toString() ?? code,
              businessName: business?['name']?.toString() ?? 'Business',
              promoTitle: promotion?['title']?.toString() ?? 'Promotion',
              discountLabel: _discountLabel(promotion),
              timeRemaining: _timeRemaining,
              isExpired: isExpired,
            ),
    );
  }
}

// ── Active state — clean QR card (Stitch style) ───────────────────────────────
class _ActiveView extends StatelessWidget {
  final String qrData;
  final String businessName;
  final String promoTitle;
  final String discountLabel;
  final Duration timeRemaining;
  final bool isExpired;

  const _ActiveView({
    required this.qrData,
    required this.businessName,
    required this.promoTitle,
    required this.discountLabel,
    required this.timeRemaining,
    required this.isExpired,
  });

  @override
  Widget build(BuildContext context) {
    final mm = timeRemaining.inMinutes;
    final ss = (timeRemaining.inSeconds % 60).toString().padLeft(2, '0');
    final urgent = !isExpired && timeRemaining.inMinutes < 5;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Text(
                  businessName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.violetAccent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$promoTitle · $discountLabel',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 26),
                Opacity(
                  opacity: isExpired ? 0.25 : 1,
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 220,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppTheme.textPrimary,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                if (!isExpired) ...[
                  const Text(
                    'Show this to the server to redeem',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Expires in: $mm:$ss',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: urgent ? AppTheme.errorColor : AppTheme.textPrimary,
                    ),
                  ),
                ] else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'CODE EXPIRED',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1, 1),
                duration: 400.ms,
                curve: Curves.easeOut,
              ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => context.go('/consumer'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isExpired ? AppTheme.primaryColor : AppTheme.infoColor,
                foregroundColor: Colors.white,
              ),
              child: Text(
                isExpired ? 'Back to deals' : 'Done',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success state — confetti peak + "You saved $X" ────────────────────────────
class _SuccessView extends StatelessWidget {
  final String businessName;
  final String discountLabel;
  final String promoTitle;
  final String? savedLabel;
  final VoidCallback onDone;

  const _SuccessView({
    required this.businessName,
    required this.discountLabel,
    required this.promoTitle,
    this.savedLabel,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _Confetti()),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.secondaryColor, AppTheme.successColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successColor.withOpacity(0.45),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 72, color: Colors.white),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.2, 0.2),
                      end: const Offset(1, 1),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 250.ms),
                const SizedBox(height: 28),
                const Text(
                  'Redeemed!',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.3, end: 0, delay: 200.ms, duration: 400.ms),
                const SizedBox(height: 8),
                Text(
                  'Enjoy your deal at $businessName 🎉',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ).animate().fadeIn(delay: 320.ms, duration: 400.ms),
                if (savedLabel != null) ...[
                  const SizedBox(height: 22),
                  const Text(
                    'You saved',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    savedLabel!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 46,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.successColor,
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1, 1),
                        delay: 380.ms,
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(delay: 380.ms, duration: 300.ms),
                ],
                const SizedBox(height: 28),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          discountLabel,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Flexible(
                        child: Text(
                          'unlocked on\n$promoTitle',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 450.ms)
                    .slideY(begin: 0.3, end: 0, delay: 450.ms, duration: 450.ms),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 650.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Confetti (dependency-free, plays once) ────────────────────────────────────
class _Confetti extends StatefulWidget {
  const _Confetti();

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _pieces;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    const colors = [
      AppTheme.primaryColor,
      AppTheme.accentColor,
      AppTheme.secondaryColor,
      AppTheme.warningColor,
      AppTheme.violetAccent,
    ];
    _pieces = List.generate(80, (i) {
      return _ConfettiPiece(
        x: rnd.nextDouble(),
        startDelay: rnd.nextDouble() * 0.35,
        speed: 0.7 + rnd.nextDouble() * 0.6,
        drift: (rnd.nextDouble() - 0.5) * 0.4,
        size: 6 + rnd.nextDouble() * 8,
        color: colors[rnd.nextInt(colors.length)],
        rotation: rnd.nextDouble() * math.pi * 2,
        spin: (rnd.nextDouble() - 0.5) * 8,
      );
    });
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces, _controller.value),
        ),
      ),
    );
  }
}

class _ConfettiPiece {
  final double x, startDelay, speed, drift, size, rotation, spin;
  final Color color;
  const _ConfettiPiece({
    required this.x,
    required this.startDelay,
    required this.speed,
    required this.drift,
    required this.size,
    required this.color,
    required this.rotation,
    required this.spin,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double progress;
  _ConfettiPainter(this.pieces, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in pieces) {
      final t = ((progress - p.startDelay) / (1 - p.startDelay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final dy = (t * p.speed) * (size.height + 60) - 40;
      final dx = size.width * p.x + math.sin(t * math.pi * 3) * p.drift * 80;
      final opacity = (1 - t).clamp(0.0, 1.0);
      paint.color = p.color.withOpacity(opacity);

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rotation + p.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
