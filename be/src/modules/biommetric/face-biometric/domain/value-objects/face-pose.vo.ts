import { isInRange } from '../../../../../common/application/utils';
import {
  DEFAULT_MAX_PITCH,
  DEFAULT_MAX_ROLL,
  DEFAULT_MAX_YAW,
  FACE_POSE_CONSTRAINTS,
} from '../constants';
import { FacePoseStatus } from '../enums/face-pose-status.enum';
import { FacePoseConfig } from '../type';

export class FacePose {
  constructor(
    public readonly pitch: number = 0,
    public readonly yaw: number = 0,
    public readonly roll: number = 0,
  ) {}

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
