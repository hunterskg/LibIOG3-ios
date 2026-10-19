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
import { DEFAULT_FACE_MATCH_THRESHOLD } from '../../domain/constants';
import { Face } from '../../domain/entities/face.entity';
import { EmbeddingMismatchException } from '../../domain/exceptions/embedding-mismatch.exception';
import { SimilarityCalculator } from '../../domain/services/similarity.service';
import { BoundingBox } from '../../domain/value-objects/bounding-box.vo';
import { FaceEmbedding } from '../../domain/value-objects/face-embedding.vo';
import { FaceLandmarks } from '../../domain/value-objects/landmark.vo';
import { BaseService } from '../../../../../common/application/service/base.service';

@Injectable()
export class VerifyFaceService extends BaseService {
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
    super(VerifyFaceService.name);
  }

  /**
   * So sánh trực tiếp 2 vector embedding với nhau.
   */
  compareVectors(
    candidate: FaceEmbedding,
    reference: FaceEmbedding,
    threshold = DEFAULT_FACE_MATCH_THRESHOLD,
  ): { isMatched: boolean; similarity: number } {
    const candidateNorm = candidate.l2Normalize();
    const referenceNorm = reference.l2Normalize();

    if (candidateNorm.dimension !== referenceNorm.dimension) {
      throw new EmbeddingMismatchException(
        `Embedding dimension mismatch: candidate ${candidateNorm.dimension} vs reference ${referenceNorm.dimension}`,
      );
    }

    const similarity = SimilarityCalculator.compute_cosine_similarity(
      candidateNorm,
      referenceNorm,
    );

    const isMatched = similarity >= threshold;

    return { isMatched, similarity };
  }

  /**
   * @throws {FaceNotFoundException} if no face is detected in the image
   * @throws {MultipleFacesDetectedException} if multiple faces are detected and requireSingleFace is true
   * @throws {SpoofDetectedException} if a spoof is detected by the liveness detector
   * @throws {EmbeddingMismatchException} if the extracted embedding dimension does not match the reference embedding dimension
   * @returns An object containing the match result and similarity score
   */
  async execute(
    imageOrEmbedding: Buffer | FaceEmbedding,
    referenceEmbedding: FaceEmbedding,
    bbox?: BoundingBox | null,
    threshold = DEFAULT_FACE_MATCH_THRESHOLD,
    validateQuality = true,
    requireSingleFace = true,
  ): Promise<{ isMatched: boolean; similarity: number }> {
    if (imageOrEmbedding instanceof FaceEmbedding) {
      return this.compareVectors(
        imageOrEmbedding,
        referenceEmbedding,
        threshold,
      );
    }

    const imageBuffer = imageOrEmbedding;
    if (!imageBuffer || imageBuffer.length === 0) {
      throw new Error('imageBuffer is required and cannot be empty');
    }

    let targetBbox = bbox ?? null;
    let targetLandmarks: FaceLandmarks | null = null;

    // Detect face if bbox is not provided
    if (this.detector && !targetBbox) {
      const faces = await this.detector.detect(imageBuffer);
      const targetFace = Face.ensureSingleFace(
        faces,
        requireSingleFace,
        validateQuality,
      );
      targetBbox = targetFace.bbox;
      targetLandmarks = targetFace.landmarks;
    }

    // Check liveness if liveness detector is available
    if (this.livenessDetector) {
      const livenessRes =
        await this.livenessDetector.checkLiveness(imageBuffer);

      if (livenessRes.isSpoof()) {
        throw new Error('Spoof detected in the image');
      }
    }

    // check is same people by embedding
    const candidateEmb = await this.embedder.extractEmbedding(
      imageBuffer,
      targetBbox,
      targetLandmarks,
    );

    return this.compareVectors(candidateEmb, referenceEmbedding, threshold);
  }
}
