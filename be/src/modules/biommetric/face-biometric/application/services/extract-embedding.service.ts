import { Inject, Injectable, Optional } from '@nestjs/common';
import {
  FACE_EMBEDDER_PORT,
  FaceEmbedderPort,
} from '../ports/face-embedder.port';
import {
  FACE_DETECTOR_PORT,
  FaceDetectorPort,
} from '../ports/face-detector.port';
import {
  LIVENESS_DETECTOR_PORT,
  LivenessDetectorPort,
} from '../ports/liveness-detector.port';
import { Face } from '../../domain/entities/face.entity';
import { BoundingBox } from '../../domain/value-objects/bounding-box.vo';
import { FaceEmbedding } from '../../domain/value-objects/face-embedding.vo';
import { FaceLandmarks } from '../../domain/value-objects/landmark.vo';
import { BaseService } from '../../../../../common/application/service/base.service';

@Injectable()
export class ExtractEmbeddingService extends BaseService {
  constructor(
    @Inject(FACE_EMBEDDER_PORT)
    private readonly embedder: FaceEmbedderPort,
    @Optional()
    @Inject(FACE_DETECTOR_PORT)
    private readonly detector?: FaceDetectorPort,
    @Optional()
    @Inject(LIVENESS_DETECTOR_PORT)
    private readonly livenessDetector?: LivenessDetectorPort,
  ) {
    super(ExtractEmbeddingService.name);
  }

  /**
   * @throws {FaceNotFoundException} if no face is detected in the image
   * @throws {MultipleFacesDetectedException} if multiple faces are detected and requireSingleFace is true
   * @throws {SpoofDetectedException} if a spoof is detected by the liveness detector
   * @returns The extracted and normalized face embedding
   */
  async execute(
    imageBuffer: Buffer,
    bbox?: BoundingBox | null,
    landmarks?: FaceLandmarks | null,
    validateQuality = true,
    requireSingleFace = true,
  ): Promise<FaceEmbedding> {
    if (!imageBuffer || imageBuffer.length === 0) {
      throw new Error('imageBuffer is required and cannot be empty');
    }

    let targetBbox = bbox ?? null;
    let targetLandmarks = landmarks ?? null;

    // Detect face if bbox is not provided
    if (this.detector && !targetBbox) {
      const faces = await this.detector.detect(imageBuffer);
      const targetFace = Face.ensureSingleFace(
        faces,
        requireSingleFace,
        validateQuality,
      );
      targetBbox = targetFace.bbox;
      if (!targetLandmarks) {
        targetLandmarks = targetFace.landmarks;
      }
    }

    // Check liveness if liveness detector is available
    if (this.livenessDetector) {
      const livenessRes =
        await this.livenessDetector.checkLiveness(imageBuffer);
      if (livenessRes.isSpoof()) {
        throw new Error('Spoof detected in the image');
      }
    }

    // Extract embedding
    const embedding = await this.embedder.extractEmbedding(
      imageBuffer,
      targetBbox,
      targetLandmarks,
    );

    return embedding.l2Normalize();
  }
}
