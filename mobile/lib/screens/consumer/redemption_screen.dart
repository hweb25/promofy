import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    _loadRedemption();
  }

  Future<void> _loadRedemption() async {
    final data = await SupabaseService.client
        .from('redemptions')
        .select('*, promotions(title, description, discount_type, discount_value), businesses(name)')
        .eq('id', widget.redemptionId)
        .single();

    if (mounted) {
      setState(() {
        _redemption = data;
        _isRedeemed = data['status'] == 'redeemed';
      });

      if (!_isRedeemed) {
        _startCountdown();
        _listenForRedemption();
      }
    }
  }

  void _startCountdown() {
    final expiresAt = DateTime.parse(_redemption!['expires_at']);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = expiresAt.difference(DateTime.now());
      if (remaining.isNegative) {
        _timer?.cancel();
        if (mounted) setState(() {});
      } else {
        if (mounted) setState(() { _timeRemaining = remaining; });
      }
    });
  }

  void _listenForRedemption() {
    SupabaseService.client
        .from('redemptions')
        .stream(primaryKey: ['id'])
        .eq('id', widget.redemptionId)
        .listen((data) {
      if (data.isNotEmpty && data.first['status'] == 'redeemed' && mounted) {
        setState(() { _isRedeemed = true; });
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_redemption == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final code = _redemption!['redemption_code'] ?? '';
    final promotion = _redemption!['promotions'];
    final business = _redemption!['businesses'];
    final isExpired = _timeRemaining.isNegative || _timeRemaining == Duration.zero;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Offer')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status icon
              if (_isRedeemed) ...[
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Offer Redeemed!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.successColor),
                ),
                const SizedBox(height: 8),
                const Text('Enjoy your deal!', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
              ] else ...[
                // Business name
                Text(
                  business?['name'] ?? 'Business',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  promotion?['title'] ?? 'Promotion',
                  style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 32),

                // QR Code
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: _redemption!['qr_data'] ?? code,
                        version: QrVersions.auto,
                        size: 250,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppTheme.primaryColor,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Code text
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F2F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          code,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Timer
                if (!isExpired) ...[
                  const Text('Expires in', style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Text(
                    '${_timeRemaining.inMinutes}:${(_timeRemaining.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: _timeRemaining.inMinutes < 5 ? AppTheme.errorColor : AppTheme.textPrimary,
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'CODE EXPIRED',
                      style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primaryColor),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Show this QR code to the staff to redeem your offer',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
