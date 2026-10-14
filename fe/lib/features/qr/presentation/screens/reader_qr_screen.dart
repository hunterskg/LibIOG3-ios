
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/network/api_client.dart';
import '../../data/services/qr_token_service.dart';
import '../../domain/models/qr_token_res.dart';

class ReaderQrScreen extends StatefulWidget {
  const ReaderQrScreen({
    super.key,
    required this.apiClient,
  });

  final ApiClient apiClient;

  @override
  State<ReaderQrScreen> createState() => _ReaderQrScreenState();
}

class _ReaderQrScreenState extends State<ReaderQrScreen> {
  late final QrTokenService _qrTokenService;

  QrTokenRes? _qrToken;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _qrTokenService = QrTokenService(widget.apiClient);
    _loadQrToken();
  }

  Future<void> _loadQrToken() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _qrTokenService.createToken();

      if (!mounted) return;

      setState(() {
        _qrToken = result;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mã checkout'),
      ),
      body: Center(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            const Text('Không thể tạo mã QR'),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQrToken,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final token = _qrToken!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Mã QR checkout',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: QrImageView(
            data: token.token,
            version: QrVersions.auto,
            size: 220,
          ),
        ),
        const SizedBox(height: 16),
        const Text('Quét mã QR để checkout'),
        const SizedBox(height: 8),
        Text(
          'Hết hạn: ${token.expiresAt}',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loadQrToken,
          child: const Text('Tạo mã mới'),
        ),
      ],
    );
  }
}