import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_client.dart';
import '../../data/services/qr_verify_service.dart';

class StaffScannerScreen extends StatefulWidget {
  final String action;

  const StaffScannerScreen({super.key, required this.action});

  @override
  State<StaffScannerScreen> createState() => _StaffScannerScreenState();
}

class _StaffScannerScreenState extends State<StaffScannerScreen> {
  late final MobileScannerController _cameraController;
  late final QrVerifyService _qrVerifyService;

  bool _isProcessing = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();

    _cameraController = MobileScannerController();
    _qrVerifyService = QrVerifyService(context.read<ApiClient>());
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    String? token;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        token = value;
        break;
      }
    }

    if (token == null) return;

    setState(() {
      _isProcessing = true;
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    await _cameraController.stop();

    try {
      final result = await _qrVerifyService.verifyToken(token);

      if (!mounted) return;

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _scanAgain() async {
    setState(() {
      _isProcessing = false;
      _isLoading = false;
      _errorMessage = null;
      _result = null;
    });

    await _cameraController.start();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.action == 'CHECK_IN'
              ? 'Quét mã check-in'
              : 'Quét mã check-out',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Đưa mã QR của độc giả vào khung quét',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              if (!_isProcessing)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MobileScanner(
                      controller: _cameraController,
                      onDetect: _onDetect,
                    ),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(height: 20),
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                const Text('Đang xác thực mã QR...'),
              ],
              if (_result != null) ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 8),
                Text(
                  _result!['valid'] == true
                      ? 'Xác thực QR thành công'
                      : 'QR không hợp lệ',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_result!['readerId'] != null)
                  Text('Reader ID: ${_result!['readerId']}'),
                if (_result!['scannedAt'] != null)
                  Text('Thời gian: ${_result!['scannedAt']}'),
              ],
              if (_errorMessage != null) ...[
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                const Text(
                  'Không thể xác thực mã QR',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(_errorMessage!, textAlign: TextAlign.center),
              ],
              if (_isProcessing) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _scanAgain,
                    child: const Text('Quét mã tiếp theo'),
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
