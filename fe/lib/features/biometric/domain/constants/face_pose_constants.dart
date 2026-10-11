enum FacePoseStatus { frontal, leftProfile, rightProfile, lookDown, lookUp }

class FacePoseConstraint {
  final double minPitch;
  final double maxPitch;
  final double minYaw;
  final double maxYaw;
  final double minRoll;
  final double maxRoll;

  const FacePoseConstraint({
    required this.minPitch,
    required this.maxPitch,
    required this.minYaw,
    required this.maxYaw,
    required this.minRoll,
    required this.maxRoll,
  });

  bool matches({
    required double pitch,
    required double yaw,
    required double roll,
  }) {
    return pitch >= minPitch &&
        pitch <= maxPitch &&
        yaw >= minYaw &&
        yaw <= maxYaw &&
        roll >= minRoll &&
        roll <= maxRoll;
  }
}

// Giới hạn góc lấy theo FACE_POSE_CONSTRAINTS từ backend domain
abstract final class FacePoseConstraints {
  static const Map<FacePoseStatus, FacePoseConstraint> values = {
    FacePoseStatus.frontal: FacePoseConstraint(
      minPitch: -10,
      maxPitch: 10,
      minYaw: -10,
      maxYaw: 10,
      minRoll: -10,
      maxRoll: 10,
    ),
    FacePoseStatus.leftProfile: FacePoseConstraint(
      minPitch: -15,
      maxPitch: 15,
      minYaw: -45,
      maxYaw: -25,
      minRoll: -10,
      maxRoll: 10,
    ),
    FacePoseStatus.rightProfile: FacePoseConstraint(
      minPitch: -15,
      maxPitch: 15,
      minYaw: 25,
      maxYaw: 45,
      minRoll: -10,
      maxRoll: 10,
    ),
    FacePoseStatus.lookDown: FacePoseConstraint(
      minPitch: -30,
      maxPitch: -15,
      minYaw: -15,
      maxYaw: 15,
      minRoll: -10,
      maxRoll: 10,
    ),
    FacePoseStatus.lookUp: FacePoseConstraint(
      minPitch: 15,
      maxPitch: 30,
      minYaw: -15,
      maxYaw: 15,
      minRoll: -10,
      maxRoll: 10,
    ),
  };

  static String getInstruction(FacePoseStatus pose) {
    switch (pose) {
      case FacePoseStatus.frontal:
        return 'Nhìn thẳng vào camera';
      case FacePoseStatus.leftProfile:
        return 'Nghiêng mặt sang trái một góc khoảng 30°';
      case FacePoseStatus.rightProfile:
        return 'Nghiêng mặt sang phải một góc khoảng 30°';
      case FacePoseStatus.lookDown:
        return 'Cúi mặt nhẹ xuống dưới';
      case FacePoseStatus.lookUp:
        return 'Ngẩng mặt nhẹ lên trên';
    }
  }

  static String getBackendName(FacePoseStatus pose) {
    switch (pose) {
      case FacePoseStatus.frontal:
        return 'FRONTAL';
      case FacePoseStatus.leftProfile:
        return 'LEFT_PROFILE';
      case FacePoseStatus.rightProfile:
        return 'RIGHT_PROFILE';
      case FacePoseStatus.lookDown:
        return 'LOOK_DOWN';
      case FacePoseStatus.lookUp:
        return 'LOOK_UP';
    }
  }
}
