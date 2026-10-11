import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';

import 'package:fe/core/constants/api_constants.dart';
import 'package:fe/core/network/api_client.dart';
import 'package:fe/core/network/api_exception.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe/features/biometric/data/services/face_biometric_service.dart';
import 'package:fe/features/biometric/domain/constants/face_pose_constants.dart';
import 'package:fe/shared/widgets/app_button.dart';
import 'package:fe/shared/widgets/app_card.dart';

class FaceRegisterScreen extends StatefulWidget {
  const FaceRegisterScreen({super.key});

  @override
  State<FaceRegisterScreen> createState() => _FaceRegisterScreenState();
}

class _FaceRegisterScreenState extends State<FaceRegisterScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  FaceBiometricService? _faceBiometricService;
  late final String _requestId;

  bool _isCameraInitialized = false;
  bool _isProcessingFrame = false;
  bool _isDetecting = false;
  bool _isCapturingManual = false;
  bool _isUploading = false;
  bool _isStreamCooldown = false;
  String? _initError;
  String? _statusMessage;

  final List<FacePoseStatus> _requiredPoses = const [
    FacePoseStatus.frontal,
    FacePoseStatus.leftProfile,
    FacePoseStatus.rightProfile,
    FacePoseStatus.lookDown,
    FacePoseStatus.lookUp,
  ];
  int _currentPoseIndex = 0;
  bool _isCurrentPoseMatched = false;
  bool _isCompleted = false;

  FacePoseStatus get _targetPose => _requiredPoses[_currentPoseIndex];

  bool get _isMobilePlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  void initState() {
    super.initState();
    _requestId = 'reg-${DateTime.now().millisecondsSinceEpoch}';
    if (_isMobilePlatform) {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableLandmarks: true,
          enableClassification: true,
        ),
      );
    }
    _initCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_faceBiometricService == null) {
      final auth = context.read<AuthProvider>();
      final client = ApiClient(
        baseUrl: ApiConstants.baseUrl,
        getAccessToken: () async => auth.accessToken,
      );
      _faceBiometricService = FaceBiometricService(client);
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _initError = 'Không tìm thấy thiết bị camera');
        return;
      }

      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final ImageFormatGroup? imageFormatGroup;
      if (kIsWeb) {
        imageFormatGroup = null;
      } else if (Platform.isAndroid) {
        imageFormatGroup = ImageFormatGroup.nv21;
      } else if (Platform.isIOS) {
        imageFormatGroup = ImageFormatGroup.bgra8888;
      } else {
        imageFormatGroup = null; // Desktop (Windows/macOS/Linux)
      }

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: imageFormatGroup,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;
      setState(() => _isCameraInitialized = true);
      _startDetectionStream();
    } catch (e) {
      if (!mounted) return;
      setState(() => _initError = 'Lỗi khởi tạo camera: $e');
    }
  }

  void _startDetectionStream() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (!_isMobilePlatform || _faceDetector == null) return;

    try {
      setState(() => _isDetecting = true);

      controller.startImageStream((CameraImage image) async {
        if (_isProcessingFrame ||
            _isCompleted ||
            !_isDetecting ||
            _isStreamCooldown) {
          return;
        }
        _isProcessingFrame = true;

        try {
          final inputImage = _convertCameraImage(image, controller.description);
          if (inputImage == null) return;

          final faces = await _faceDetector!.processImage(inputImage);
          if (!mounted) return;

          if (faces.length == 1) {
            final face = faces.first;
            final pitch = face.headEulerAngleX ?? 0.0;
            final yaw = face.headEulerAngleY ?? 0.0;
            final roll = face.headEulerAngleZ ?? 0.0;

            final constraint = FacePoseConstraints.values[_targetPose];
            final isMatched =
                constraint?.matches(pitch: pitch, yaw: yaw, roll: roll) ??
                false;

            if (isMatched &&
                !_isCurrentPoseMatched &&
                !_isUploading &&
                !_isStreamCooldown) {
              setState(() => _isCurrentPoseMatched = true);
              await _sendPoseFrameToBackend();
            } else if (!isMatched && _isCurrentPoseMatched && !_isUploading) {
              setState(() => _isCurrentPoseMatched = false);
            }
          } else {
            if (_isCurrentPoseMatched && !_isUploading) {
              setState(() => _isCurrentPoseMatched = false);
            }
          }
        } catch (_) {
          // Drop frame
        } finally {
          _isProcessingFrame = false;
        }
      });
    } catch (_) {
      // Platform khong ho tro stream
    }
  }

  // ponytail: chup anh va xac thuc pose tren Web/Desktop; them WebAssembly/TF.js khi can offline
  Future<void> _captureManualPose() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isCapturingManual ||
        _isUploading) {
      return;
    }

    setState(() {
      _isCapturingManual = true;
      _statusMessage = 'Đang chụp ảnh...';
    });

    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;

      if (bytes.isNotEmpty) {
        await _uploadFaceToBackend(bytes);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = 'Lỗi chụp ảnh: $e';
      setState(() => _statusMessage = msg);
      _showErrorSnackBar(msg);
    } finally {
      if (mounted) {
        setState(() => _isCapturingManual = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendPoseFrameToBackend() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isUploading) {
      return;
    }

    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      await _uploadFaceToBackend(bytes);
    } catch (e) {
      if (!mounted) return;
      final msg = 'Lỗi chụp ảnh gửi máy chủ: $e';
      setState(() {
        _isCurrentPoseMatched = false;
        _statusMessage = msg;
      });
      _showErrorSnackBar(msg);
    }
  }

  Future<void> _uploadFaceToBackend(List<int> bytes) async {
    final service = _faceBiometricService;
    if (service == null) return;

    setState(() {
      _isUploading = true;
      _statusMessage = 'Đang xác thực với máy chủ...';
    });

    try {
      final poseBackendName = FacePoseConstraints.getBackendName(_targetPose);
      final res = await service.registerFace(
        imageBytes: bytes,
        requestId: _requestId,
        facePose: poseBackendName,
      );

      if (!mounted) return;
      if (res.isSuccess) {
        setState(() {
          _isCompleted = true;
          _isDetecting = false;
          _statusMessage = 'Đăng ký khuôn mặt thành công!';
        });
        if (_isMobilePlatform) {
          await _cameraController?.stopImageStream();
        }
        return;
      }

      if (res.isInProgress) {
        await _onPosePassed();
        return;
      }

      final msg = 'Phản hồi không hợp lệ từ máy chủ: ${res.message}';
      setState(() {
        _isCurrentPoseMatched = false;
        _statusMessage = msg;
      });
      _showErrorSnackBar(msg);
      await _startCooldown();
    } catch (e) {
      if (!mounted) return;
      final friendly = _formatApiError(e);
      setState(() {
        _isCurrentPoseMatched = false;
        _statusMessage = friendly;
      });
      _showErrorSnackBar(friendly);
      await _startCooldown();
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _startCooldown() async {
    _isStreamCooldown = true;
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      _isStreamCooldown = false;
    }
  }

  String _formatApiError(Object e) {
    if (e is ApiException) {
      return e.message;
    }
    return 'Lỗi xác thực máy chủ: $e';
  }

  Future<void> _onPosePassed() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || _isCompleted) return;

    if (_currentPoseIndex < _requiredPoses.length - 1) {
      setState(() {
        _currentPoseIndex++;
        _isCurrentPoseMatched = false;
        _statusMessage = null;
      });
    } else {
      setState(() {
        _statusMessage = 'Đang xử lý khuôn mặt, vui lòng giữ nguyên tư thế...';
      });
    }
  }

  InputImage? _convertCameraImage(
    CameraImage image,
    CameraDescription description,
  ) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;
    final rotation =
        InputImageRotationValue.fromRawValue(description.sensorOrientation) ??
        InputImageRotation.rotation0deg;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Quét & Đăng ký khuôn mặt'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.charcoal900,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(padding: AppSpacing.p4, child: _buildBody()),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_initError != null) {
      return Center(
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.danger,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.s3),
              Text(
                _initError!,
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s4),
              AppButton(text: 'Thử lại', onPressed: _initCamera),
            ],
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isCompleted) {
      return Center(
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 64,
              ),
              const SizedBox(height: AppSpacing.s3),
              Text('Quét khuôn mặt hoàn tất!', style: AppTextStyles.h2),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Tất cả dáng mặt đã được xác thực thành công.',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.charcoal500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s5),
              AppButton(
                text: 'Hoàn tất & Quay lại',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    final borderColor = _isCurrentPoseMatched
        ? AppColors.success
        : AppColors.accent500;

    return Column(
      children: [
        Row(
          children: List.generate(_requiredPoses.length, (index) {
            final isDone = index < _currentPoseIndex;
            final isCurrent = index == _currentPoseIndex;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.success
                      : isCurrent
                      ? AppColors.accent500
                      : AppColors.neutral300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(
          'Bước ${_currentPoseIndex + 1}/${_requiredPoses.length}: ${FacePoseConstraints.getInstruction(_targetPose)}',
          style: AppTextStyles.h3.copyWith(
            color: _isCurrentPoseMatched
                ? AppColors.success
                : AppColors.charcoal900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s3),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_cameraController!),
                Center(
                  child: Container(
                    width: 240,
                    height: 320,
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 4),
                      borderRadius: BorderRadius.circular(160),
                    ),
                  ),
                ),
                if (kIsWeb)
                  Positioned(
                    top: 16,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Chế độ Web: Trình duyệt không hỗ trợ stream frame ML Kit. Sử dụng thiết bị di động (Android/iOS) để quét tự động.',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.charcoal900.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusMessage ??
                          (_isCurrentPoseMatched
                              ? 'Đã khớp! Giữ nguyên vị trí...'
                              : 'Căn chỉnh khuôn mặt vào khung'),
                      style: AppTextStyles.bodySm.copyWith(
                        color: _isCurrentPoseMatched
                            ? AppColors.successLight
                            : AppColors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!_isMobilePlatform) ...[
          const SizedBox(height: AppSpacing.s3),
          AppButton(
            text: _isUploading
                ? 'Đang gửi lên máy chủ...'
                : (_isCapturingManual
                      ? 'Đang chụp ảnh...'
                      : 'Chụp ảnh & Xác nhận góc mặt'),
            isLoading: _isCapturingManual || _isUploading,
            onPressed: (_isCapturingManual || _isUploading)
                ? null
                : _captureManualPose,
          ),
        ],
      ],
    );
  }
}
