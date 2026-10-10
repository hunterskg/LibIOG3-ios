import { FacePoseStatus } from './enums/face-pose-status.enum';
import { FacePoseConfig } from './type';

// Face quality thresholds
export const DEFAULT_MAX_BLUR = 0.5;
export const DEFAULT_MIN_BLUR_SCORE = 100.0;
export const DEFAULT_MIN_FACE_SIZE = 80.0;
export const DEFAULT_MAX_PITCH = 20.0;
export const DEFAULT_MAX_YAW = 20.0;
export const DEFAULT_MAX_ROLL = 20.0;

// Recognition & liveness thresholds
export const DEFAULT_SIMILARITY_THRESHOLD = 0.55;
export const DEFAULT_FACE_MATCH_THRESHOLD = 0.55;
export const DEFAULT_LIVENESS_THRESHOLD = 0.8;

export const DEFAULT_FACE_POSE_CONFIG = {
  maxPitch: DEFAULT_MAX_PITCH,
  maxYaw: DEFAULT_MAX_YAW,
  maxRoll: DEFAULT_MAX_ROLL,
};

// Cấu hình giới hạn góc cho từng trạng thái khuôn mặt phổ biến
export const FACE_POSE_CONSTRAINTS: Partial<
  Record<FacePoseStatus, FacePoseConfig>
> = {
  // Chính diện: Cả 3 góc đều gần bằng 0 (sai số tối đa từ 10 đến 15 độ)
  [FacePoseStatus.FRONTAL]: {
    maxPitch: 10,
    minPitch: -10,
    maxYaw: 10,
    minYaw: -10,
    maxRoll: 10,
    minRoll: -10,
  },

  // Nghiêng trái: Góc Yaw âm (thường từ -45° đến -25°)
  [FacePoseStatus.LEFT_PROFILE]: {
    maxPitch: 15,
    minPitch: -15,
    maxYaw: -25,
    minYaw: -45,
    maxRoll: 10,
    minRoll: -10,
  },

  // Nghiêng phải: Góc Yaw dương (thường từ +25° đến +45°)
  [FacePoseStatus.RIGHT_PROFILE]: {
    maxPitch: 15,
    minPitch: -15,
    maxYaw: 45,
    minYaw: 25,
    maxRoll: 10,
    minRoll: -10,
  },

  // Cúi xuống: Góc Pitch âm (thường từ -30° đến -15°)
  [FacePoseStatus.LOOK_DOWN]: {
    maxPitch: -15,
    minPitch: -30,
    maxYaw: 15,
    minYaw: -15,
    maxRoll: 10,
    minRoll: -10,
  },

  // Ngẩng lên: Góc Pitch dương (thường từ +15° đến +30°)
  [FacePoseStatus.LOOK_UP]: {
    maxPitch: 30,
    minPitch: 15,
    maxYaw: 15,
    minYaw: -15,
    maxRoll: 10,
    minRoll: -10,
  },
};
