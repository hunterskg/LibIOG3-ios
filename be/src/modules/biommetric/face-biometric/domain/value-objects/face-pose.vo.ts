import { isInRange } from '../../../../../common/application/utils';
import {
  DEFAULT_MAX_PITCH,
  DEFAULT_MAX_ROLL,
  DEFAULT_MAX_YAW,
  FACE_POSE_CONSTRAINTS,
} from '../constants';
import { FacePoseStatus } from '../enums/face-pose-status.enum';
import { FacePoseConfig } from '../type';
import { FaceLandmarks } from './landmark.vo';

export class FacePose {
  constructor(
    public readonly pitch: number = 0,
    public readonly yaw: number = 0,
    public readonly roll: number = 0,
  ) {}

  static fromLandmarks(landmarks?: FaceLandmarks | null): FacePose | null {
    if (!landmarks || landmarks.points.length < 5) {
      return null;
    }

    const pts = [...landmarks.points].sort((a, b) => a.index - b.index);
    const [p0, p1, p2, p3, p4] = pts;

    // 0: left eye, 1: right eye, 2: nose tip, 3: left mouth, 4: right mouth
    const eyeDx = p1.x - p0.x;
    const eyeDy = p1.y - p0.y;
    const roll = (Math.atan2(eyeDy, eyeDx) * 180) / Math.PI;

    // Yaw: asymmetry between distance(p0, p2) and distance(p1, p2)
    const d0 = Math.hypot(p2.x - p0.x, p2.y - p0.y);
    const d1 = Math.hypot(p2.x - p1.x, p2.y - p1.y);
    const totalEyeNose = d0 + d1;
    const yawRatio = totalEyeNose > 0 ? (d1 - d0) / totalEyeNose : 0;
    const yaw = yawRatio * 75;

    // Pitch: vertical offset of nose relative to eye and mouth midpoints
    const eyeY = (p0.y + p1.y) / 2;
    const mouthY = (p3.y + p4.y) / 2;
    const faceHeight = mouthY - eyeY;
    const noseToEye = p2.y - eyeY;
    const mouthToNose = mouthY - p2.y;
    const pitchRatio =
      faceHeight > 0 ? (mouthToNose - noseToEye) / faceHeight : 0;
    const pitch = pitchRatio * 60;

    return new FacePose(
      Math.round(pitch * 10) / 10,
      Math.round(yaw * 10) / 10,
      Math.round(roll * 10) / 10,
    );
  }

  matches(config?: FacePoseConfig): boolean {
    if (!config) return false;
    return (
      isInRange(
        this.pitch,
        config.minPitch ?? -Infinity,
        config.maxPitch ?? Infinity,
      ) &&
      isInRange(
        this.yaw,
        config.minYaw ?? -Infinity,
        config.maxYaw ?? Infinity,
      ) &&
      isInRange(
        this.roll,
        config.minRoll ?? -Infinity,
        config.maxRoll ?? Infinity,
      )
    );
  }

  isInPose(pose: FacePoseStatus): boolean {
    return this.matches(FACE_POSE_CONSTRAINTS[pose]);
  }

  getStatus(): FacePoseStatus {
    const entry = (
      Object.entries(FACE_POSE_CONSTRAINTS) as [
        FacePoseStatus,
        FacePoseConfig,
      ][]
    ).find(([, config]) => this.matches(config));

    return entry ? entry[0] : FacePoseStatus.NON_FRONTAL;
  }

  checkQuality(
    options: { maxPitch?: number; maxYaw?: number; maxRoll?: number } = {},
  ): string[] {
    const limits: [string, number, number][] = [
      ['roll', this.roll, options.maxRoll ?? DEFAULT_MAX_ROLL],
      ['pitch', this.pitch, options.maxPitch ?? DEFAULT_MAX_PITCH],
      ['yaw', this.yaw, options.maxYaw ?? DEFAULT_MAX_YAW],
    ];

    return limits
      .filter(([, val, max]) => Math.abs(val) > max)
      .map(
        ([name, val, max]) =>
          `Góc ${name} vượt ngưỡng: ${name}=${val.toFixed(1)}° (|${name}| > ${max.toFixed(1)}°)`,
      );
  }
}
