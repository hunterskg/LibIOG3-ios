import { BoundingBox } from '../../domain/value-objects/bounding-box.vo';
import { FaceEmbedding } from '../../domain/value-objects/face-embedding.vo';
import { FaceLandmarks } from '../../domain/value-objects/landmark.vo';

export const FACE_EMBEDDER_PORT = 'FACE_EMBEDDER_PORT';

export interface FaceEmbedderPort {
  extractEmbedding(
    imageBuffer: Buffer,
    bbox?: BoundingBox | null,
    landmarks?: FaceLandmarks | null,
  ): Promise<FaceEmbedding>;
}
