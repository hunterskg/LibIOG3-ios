
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import 'package:fe/core/network/api_client.dart';
import 'package:fe/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe/features/qr/data/services/checkin_out_service.dart';

class StaffScannerScreen extends StatefulWidget {
  const StaffScannerScreen({super.key});

  @override
  State<StaffScannerScreen> createState() => _StaffScannerScreenState();
}

class _StaffScannerScreenState extends State<StaffScannerScreen> {
  late final MobileScannerController _cameraController;
  late final CheckInOutService _checkInOutService;

  bool _isProcessing = false;
  bool _isLoading = false;
  bool _cameraError = false;
  String? _errorMessage;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();

    _cameraController = MobileScannerController();

    final apiClient = context.read<ApiClient>();
    _checkInOutService = CheckInOutService(
      baseUrl: apiClient.baseUrl,
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _cameraError) return;

    String? token;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();

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

    try {
      await _cameraController.stop();

      final accessToken = context.read<AuthProvider>().accessToken;

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception(
          'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        );
      }

      final response = await _checkInOutService.checkInOut(
        qrToken: token,
        accessToken: accessToken,
      );

      if (!mounted) return;

      setState(() {
        _result = response;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _scanAgain() async {
    setState(() {
      _isProcessing = false;
      _isLoading = false;
      _cameraError = false;
      _errorMessage = null;
      _result = null;
    });

    try {
      await _cameraController.start();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cameraError = true;
        _errorMessage = 'Không thể mở camera: $e';
      });
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _result?['data'];
    final action = data is Map ? data['action'] : null;
    final state = data is Map ? data['state'] : null;
    final isCheckIn = action == 'CHECK_IN' || state == 'IN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét QR'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Quét mã QR của độc giả để tự động ghi nhận check-in hoặc check-out.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _cameraError
                      ? Center(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                _errorMessage ?? 'Không thể khởi động camera.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        )
                      : _isProcessing
                          ? const Center(
                              child: Icon(
                                Icons.qr_code_scanner,
                                size: 72,
                              ),
                            )
                          : MobileScanner(
                              controller: _cameraController,
                              onDetect: _onDetect,
                              errorBuilder: (context, error) {
                                return Center(
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.camera_alt_outlined,
                                            size: 48,
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Không thể khởi động camera',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Mã lỗi: ${error.errorCode}\n$error',
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                const Text('Đang xử lý yêu cầu...'),
              ],
              if (_result != null) ...[
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  isCheckIn ? 'Check-in thành công' : 'Check-out thành công',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_result!['message'] is String)
                  Text(
                    _result!['message'] as String,
                    textAlign: TextAlign.center,
                  ),
              ],
              if (_errorMessage != null && !_cameraError) ...[
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 40,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Không thể thực hiện yêu cầu',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                ),
              ],
              if (_isProcessing) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _scanAgain,
                    child: const Text('Quét mã tiếp theo'),
                  ),
                ),
              ],
              if (_cameraError) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _scanAgain,
                    child: const Text('Thử mở camera lại'),
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
