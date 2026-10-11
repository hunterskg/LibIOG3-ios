import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
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
  late final FaceDetector _faceDetector;

  bool _isCameraInitialized = false;
  bool _isProcessingFrame = false;
  bool _isDetecting = false;
  String? _initError;

  final List<FacePoseStatus> _requiredPoses = const [
    FacePoseStatus.frontal,
    FacePoseStatus.leftProfile,
    FacePoseStatus.rightProfile,
  ];
  int _currentPoseIndex = 0;
  bool _isCurrentPoseMatched = false;
  bool _isCompleted = false;

  FacePoseStatus get _targetPose => _requiredPoses[_currentPoseIndex];

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableLandmarks: true,
        enableClassification: true,
      ),
    );
    _initCamera();
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

    // Web hoặc desktop plugin không hỗ trợ startImageStream
    if (kIsWeb || !controller.value.description.lensDirection.toString().isNotEmpty) {
      return;
    }

    try {
      // Bỏ qua nếu nền tảng không hỗ trợ streaming (camera-web ném assert supportsImageStreaming)
      setState(() => _isDetecting = true);

      controller.startImageStream((CameraImage image) async {
        if (_isProcessingFrame || _isCompleted || !_isDetecting) return;
        _isProcessingFrame = true;

        try {
          final inputImage = _convertCameraImage(image, controller.description);
          if (inputImage == null) return;

          final faces = await _faceDetector.processImage(inputImage);
          if (!mounted) return;

          if (faces.length == 1) {
            final face = faces.first;
            final pitch = face.headEulerAngleX ?? 0.0;
            final yaw = face.headEulerAngleY ?? 0.0;
            final roll = face.headEulerAngleZ ?? 0.0;

            final constraint = FacePoseConstraints.values[_targetPose];
            final isMatched =
                constraint?.matches(pitch: pitch, yaw: yaw, roll: roll) ?? false;

            if (isMatched && !_isCurrentPoseMatched) {
              setState(() => _isCurrentPoseMatched = true);
              await _onPosePassed();
            } else if (!isMatched && _isCurrentPoseMatched) {
              setState(() => _isCurrentPoseMatched = false);
            }
          } else {
            if (_isCurrentPoseMatched) {
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
      // Nền tảng không hỗ trợ image stream
    }
  }

  Future<void> _onPosePassed() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || _isCompleted) return;

    if (_currentPoseIndex < _requiredPoses.length - 1) {
      setState(() {
        _currentPoseIndex++;
        _isCurrentPoseMatched = false;
      });
    } else {
      setState(() {
        _isCompleted = true;
        _isDetecting = false;
      });
      await _cameraController?.stopImageStream();
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
    _faceDetector.close();
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
                      _isCurrentPoseMatched
                          ? 'Đã khớp! Giữ nguyên vị trí...'
                          : 'Căn chỉnh khuôn mặt vào khung',
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
      ],
    );
  }
}
