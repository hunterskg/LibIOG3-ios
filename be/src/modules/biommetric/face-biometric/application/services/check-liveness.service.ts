import { Inject, Injectable, Optional } from '@nestjs/common';
import {
  LIVENESS_DETECTOR_PORT,
  LivenessDetectorPort,
} from '../ports/liveness-detector.port';
import {
  FACE_DETECTOR_PORT,
  FaceDetectorPort,
} from '../ports/face-detector.port';
import { LivenessResult } from '../../domain/entities/liveness-result.entity';
import { FaceNotFoundException } from '../../domain/exceptions/face-not-found.exception';
import { BaseService } from '../../../../../common/application/service/base.service';

@Injectable()
export class CheckLivenessService extends BaseService {
  constructor(
    @Inject(LIVENESS_DETECTOR_PORT)
    private readonly livenessDetector: LivenessDetectorPort,
    @Optional()
    @Inject(FACE_DETECTOR_PORT)
    private readonly detector?: FaceDetectorPort,
  ) {
    super(CheckLivenessService.name);
  }

  /**
   * @throws {FaceNotFoundException} if no face is detected in the image
   * @returns The liveness result containing the liveness status and score
   */
  async execute(imageBuffer: Buffer): Promise<LivenessResult> {
    if (!imageBuffer || imageBuffer.length === 0) {
      throw new Error('imageBuffer is required and cannot be empty');
    }

    if (this.detector) {
      const faces = await this.detector.detect(imageBuffer);
      if (faces.length === 0) {
        throw new FaceNotFoundException('No face detected for liveness check');
      }
    }

    return this.livenessDetector.checkLiveness(imageBuffer);
  }
}
