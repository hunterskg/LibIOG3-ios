
import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fe/core/network/api_client.dart';
import 'package:fe/core/network/api_exception.dart';
import 'package:fe/features/biometric/data/services/face_checkin_service.dart';

class StaffFaceScannerScreen extends StatefulWidget {
  const StaffFaceScannerScreen({super.key});

  @override
  State<StaffFaceScannerScreen> createState() =>
      _StaffFaceScannerScreenState();
}

class _StaffFaceScannerScreenState
    extends State<StaffFaceScannerScreen> {
  CameraController? _cameraController;
  late final FaceCheckInService _faceCheckInService;

  bool _isInitializing = true;
  bool _isSubmitting = false;
  String? _cameraError;
  String? _resultMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();

    _faceCheckInService = FaceCheckInService(
      context.read<ApiClient>(),
    );

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('Không tìm thấy camera trên thiết bị.');
      }

      final frontCameras = cameras.where(
        (camera) =>
            camera.lensDirection == CameraLensDirection.front,
      );

      final selectedCamera =
          frontCameras.isNotEmpty ? frontCameras.first : cameras.first;

      ImageFormatGroup? imageFormatGroup;

      if (!kIsWeb) {
        if (Platform.isAndroid) {
          imageFormatGroup = ImageFormatGroup.nv21;
        } else if (Platform.isIOS) {
          imageFormatGroup = ImageFormatGroup.bgra8888;
        }
      }

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: imageFormatGroup,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _cameraError = 'Không thể mở camera: $e';
      });
    }
  }

  Future<void> _captureAndCheckInOut() async {
    final controller = _cameraController;

    if (controller == null ||
        !controller.value.isInitialized ||
        _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _resultMessage = null;
    });

    try {
      // Chụp ảnh từ camera.
      final XFile image = await controller.takePicture();

      // Đọc bytes để service chuyển thành Base64.
      final imageBytes = await image.readAsBytes();

      // Gửi ảnh lên Backend bằng JWT của Staff.
      final response = await _faceCheckInService.checkInOut(
        imageBytes: imageBytes,
      );

      if (!mounted) return;

      final message = response['message']?.toString();

      setState(() {
        _isSuccess = true;
        _resultMessage = message?.isNotEmpty == true
            ? message
            : 'Đã gửi ảnh thành công. Hãy kiểm tra kết quả check-in/check-out.';
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _isSuccess = false;
        _resultMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSuccess = false;
        _resultMessage = 'Đã xảy ra lỗi khi xử lý khuôn mặt: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in / Check-out bằng khuôn mặt'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Nhận diện khuôn mặt Reader',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Đặt khuôn mặt vào giữa khung hình, đủ sáng, '
                    'sau đó nhấn nút chụp ảnh.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Camera preview.
                  Container(
                    height: 360,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _isInitializing
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : _cameraError != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    _cameraError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : controller != null &&
                                    controller.value.isInitialized
                                ? CameraPreview(controller)
                                : const Center(
                                    child: Text(
                                      'Camera chưa sẵn sàng.',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                  ),

                  const SizedBox(height: 20),

                  // Capture and submit.
                  ElevatedButton.icon(
                    onPressed: _isInitializing ||
                            _cameraError != null ||
                            controller == null ||
                            !controller.value.isInitialized ||
                            _isSubmitting
                        ? null
                        : _captureAndCheckInOut,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.face),
                    label: Text(
                      _isSubmitting
                          ? 'Đang nhận diện...'
                          : 'Chụp ảnh và check-in/check-out',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                    ),
                  ),

                  if (_resultMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _isSuccess
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isSuccess
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _isSuccess
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: _isSuccess
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_resultMessage!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
