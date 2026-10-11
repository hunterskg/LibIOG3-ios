/*
https://docs.nestjs.com/providers#services
*/

import { Injectable } from '@nestjs/common';
import { CheckLivenessService } from './check-liveness.service';
import { DetectFaceService } from './detect-face.service';
import { ExtractEmbeddingService } from './extract-embedding.service';
import { FaceEmbedding } from '../../domain/value-objects/face-embedding.vo';
import { SpoofDetectedException } from '../../domain/exceptions/spoof-detected.exception';

@Injectable()
export class FaceBiometricService {
  constructor(
    private readonly checkLivenessService: CheckLivenessService,
    private readonly detectFaceService: DetectFaceService,
    private readonly extractEmbeddingService: ExtractEmbeddingService,
  ) {}

  async registerFace(imageBuffer: Buffer): Promise<FaceEmbedding> {
    const maxFaces = 1; // Only allow one face for registration

    // 1. Detect face
    const [faceDetected] = await this.detectFaceService.execute(
      imageBuffer,
      maxFaces,
    );

    // 2. Check liveness
    const livenesRes = await this.checkLivenessService.execute(imageBuffer);

    if (livenesRes.isSpoof()) {
      throw new SpoofDetectedException(
        `Face detected but failed liveness check. `,
      );
    }

    // 3. Extract embedding
    const embedding = await this.extractEmbeddingService.execute(
      imageBuffer,
      faceDetected.bbox,
      faceDetected.landmarks,
      true, // validateQuality
      true, // requireSingleFace
    );

    return embedding;
  }
}
