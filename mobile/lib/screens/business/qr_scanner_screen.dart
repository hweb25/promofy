import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../config/theme.dart';
import '../../providers/business_provider.dart';
import '../../services/promotion_service.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;
  _ScanResult? _result;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _result != null) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _isProcessing = true);
    _controller.stop();

    try {
      final business = ref.read(myBusinessProvider).valueOrNull;
      if (business == null) throw Exception('No business found');

      // Try to parse the QR data to extract the code
      String code = barcode.rawValue!;
      try {
        // QR might contain JSON with a 'code' field
        if (code.contains('code')) {
          final match = RegExp(r'"code"\s*:\s*"(\w+)"').firstMatch(code);
          if (match != null) code = match.group(1)!;
        }
      } catch (_) {}

      final service = PromotionService();
      final result = await service.validateRedemption(
        code: code,
        businessId: business.id,
      );

      setState(() {
        _result = _ScanResult(
          success: result['success'] == true,
          message: result['success'] == true
              ? 'Offer redeemed successfully!'
              : result['error'] ?? 'Validation failed',
        );
      });
    } catch (e) {
      setState(() {
        _result = _ScanResult(success: false, message: 'Error: $e');
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _resetScanner() {
    setState(() { _result = null; });
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: _result != null
          ? _buildResult()
          : Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
                // Scan overlay
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primaryColor, width: 3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                // Top overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.25,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
                // Bottom instruction
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      if (_isProcessing)
                        const CircularProgressIndicator(color: Colors.white)
                      else
                        const Text(
                          'Point your camera at the\ncustomer\'s QR code',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                // Manual code entry
                Positioned(
                  bottom: 16,
                  left: 20,
                  right: 20,
                  child: TextButton(
                    onPressed: () => _showManualEntry(context),
                    child: const Text(
                      'Enter code manually',
                      style: TextStyle(color: Colors.white, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildResult() {
    final success = _result!.success;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: (success ? AppTheme.successColor : AppTheme.errorColor).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check_circle : Icons.cancel,
                size: 80,
                color: success ? AppTheme.successColor : AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              success ? 'Success!' : 'Failed',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: success ? AppTheme.successColor : AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _result!.message,
              style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _resetScanner,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Another'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualEntry(BuildContext context) {
    final codeController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter Redemption Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: 'e.g. A1B2C3D4'),
              style: const TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _controller.stop();
                  setState(() => _isProcessing = true);
                  _validateManualCode(codeController.text.trim());
                },
                child: const Text('Validate'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validateManualCode(String code) async {
    try {
      final business = ref.read(myBusinessProvider).valueOrNull;
      if (business == null) throw Exception('No business found');

      final service = PromotionService();
      final result = await service.validateRedemption(code: code, businessId: business.id);

      setState(() {
        _result = _ScanResult(
          success: result['success'] == true,
          message: result['success'] == true ? 'Offer redeemed successfully!' : result['error'] ?? 'Validation failed',
        );
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _result = _ScanResult(success: false, message: 'Error: $e');
        _isProcessing = false;
      });
    }
  }
}

class _ScanResult {
  final bool success;
  final String message;
  _ScanResult({required this.success, required this.message});
}
