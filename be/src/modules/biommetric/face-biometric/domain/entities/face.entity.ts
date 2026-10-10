import {
  DEFAULT_MAX_PITCH,
  DEFAULT_MAX_ROLL,
  DEFAULT_MAX_YAW,
  DEFAULT_MIN_BLUR_SCORE,
  DEFAULT_MIN_FACE_SIZE,
} from '../constants';
import { FaceNotFoundException } from '../exceptions/face-not-found.exception';
import { LowFaceQualityException } from '../exceptions/low-face-quality.exception';
import { MultipleFacesDetectedException } from '../exceptions/multiple-faces-detected.exception';
import { BoundingBox } from '../value-objects/bounding-box.vo';
import { FaceLandmarks } from '../value-objects/landmark.vo';
import { FacePose } from '../value-objects/face-pose.vo';

export class Face {
  public id!: string;
  public bbox!: BoundingBox;
  public landmarks!: FaceLandmarks | null;
  public confidence!: number;
  public imagePath!: string | null;
  public blurScore!: number | null;
  public pose!: FacePose | null;

  static create(
    id: string,
    bbox: BoundingBox,
    landmarks: FaceLandmarks | null = null,
    confidence = 0.0,
    imagePath: string | null = null,
    blurScore: number | null = null,
    pose: FacePose | null = null,
  ): Face {
    const face = new Face();
    face.id = id;
    face.bbox = bbox;
    face.landmarks = landmarks;
    face.confidence = confidence;
    face.imagePath = imagePath;
    face.blurScore = blurScore;
    face.pose = pose;
    return face;
  }

  static ensureSingleFace(
    faces: Face[],
    requireSingleFace = true,
    validateQuality = true,
  ): Face {
    if (!faces || faces.length === 0) {
      throw new FaceNotFoundException('No face detected in image');
    }
    if (requireSingleFace && faces.length > 1) {
      throw new MultipleFacesDetectedException(
        `Expected single face, detected ${faces.length}`,
      );
    }
    const targetFace = faces[0];
    if (validateQuality) {
      targetFace.validateQuality();
    }
    return targetFace;
  }

  checkQuality(
    options: {
      maxPitch?: number;
      maxYaw?: number;
      minBlur?: number;
      minFaceSize?: number;
      maxRoll?: number;
    } = {},
  ): { isValid: boolean; violations: string[] } {
    const maxPitch = options.maxPitch ?? DEFAULT_MAX_PITCH;
    const maxYaw = options.maxYaw ?? DEFAULT_MAX_YAW;
    const minBlur = options.minBlur ?? DEFAULT_MIN_BLUR_SCORE;
    const minFaceSize = options.minFaceSize ?? DEFAULT_MIN_FACE_SIZE;
    const maxRoll = options.maxRoll ?? DEFAULT_MAX_ROLL;

    const violations: string[] = [];

    if (this.blurScore !== null && this.blurScore < minBlur) {
      violations.push(
        `Ảnh quá mờ: Laplacian variance=${this.blurScore.toFixed(2)} < ngưỡng ${minBlur.toFixed(2)}`,
      );
    }

    if (this.bbox.width < minFaceSize || this.bbox.height < minFaceSize) {
      violations.push(
        `Kích thước khuôn mặt quá nhỏ: ${this.bbox.width.toFixed(1)}x${this.bbox.height.toFixed(1)} < ${minFaceSize.toFixed(1)}x${minFaceSize.toFixed(1)}`,
      );
    }

    if (this.pose) {
      violations.push(...this.pose.checkQuality({ maxPitch, maxYaw, maxRoll }));
    }

    return { isValid: violations.length === 0, violations };
  }

  isValidQuality(options?: {
    maxPitch?: number;
    maxYaw?: number;
    minBlur?: number;
    minFaceSize?: number;
    maxRoll?: number;
  }): boolean {
    return this.checkQuality(options).isValid;
  }

  validateQuality(options?: {
    maxPitch?: number;
    maxYaw?: number;
    minBlur?: number;
    minFaceSize?: number;
    maxRoll?: number;
  }): void {
    const { isValid, violations } = this.checkQuality(options);
    if (!isValid) {
      throw new LowFaceQualityException(violations.join('; '));
    }
  }
}
