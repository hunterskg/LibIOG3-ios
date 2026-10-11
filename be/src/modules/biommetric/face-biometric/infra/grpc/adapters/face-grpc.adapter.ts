import { Inject, Injectable, OnModuleInit } from '@nestjs/common';
import { ClientGrpc } from '@nestjs/microservices';
import { firstValueFrom } from 'rxjs';
import { FaceDetectorPort } from '../../../application/ports/face-detector.port';
import { FaceEmbedderPort } from '../../../application/ports/face-embedder.port';
import { LivenessDetectorPort } from '../../../application/ports/liveness-detector.port';
import { Face } from '../../../domain/entities/face.entity';
import { LivenessResult } from '../../../domain/entities/liveness-result.entity';
import { LivenessStatus } from '../../../domain/enums/liveness-status.enum';
import { BoundingBox } from '../../../domain/value-objects/bounding-box.vo';
import { FaceEmbedding } from '../../../domain/value-objects/face-embedding.vo';
import {
  FaceLandmarks,
  Point2D,
} from '../../../domain/value-objects/landmark.vo';
import { GrpcFaceService } from '../face-grpc.interface';
import { randomUUID } from 'crypto';

export const FACE_GRPC_CLIENT = 'FACE_GRPC_CLIENT';

@Injectable()
export class FaceGrpcAdapter
  implements
    FaceDetectorPort,
    FaceEmbedderPort,
    LivenessDetectorPort,
    OnModuleInit
{
  private faceService: GrpcFaceService;

  constructor(@Inject(FACE_GRPC_CLIENT) private readonly client: ClientGrpc) {
    this.faceService = this.client.getService<GrpcFaceService>('FaceService');
  }

  onModuleInit() {
    // Lấy instance của FaceService được định nghĩa trong face.proto
    this.faceService = this.client.getService<GrpcFaceService>('FaceService');
  }

  // 1. Nhận diện khuôn mặt
  async detect(imageBuffer: Buffer): Promise<Face[]> {
    const res = await firstValueFrom(
      this.faceService.detectFaces({ image_bytes: imageBuffer, max_faces: 5 }),
    );
    if (!res.success) return [];

    return res.detections.map((d) =>
      Face.create(
        randomUUID(),
        new BoundingBox(
          d.box.x,
          d.box.y,
          d.box.width,
          d.box.height,
          d.box.confidence,
        ),
        new FaceLandmarks(
          d.landmarks.map((lm) => new Point2D(lm.x, lm.y, lm.index)),
        ),
        d.confidence,
      ),
    );
  }

  // 2. Trích xuất vector đặc trưng 512D
  async extractEmbedding(
    imageBuffer: Buffer,
    bbox?: BoundingBox | null,
    landmarks?: FaceLandmarks | null,
  ): Promise<FaceEmbedding> {
    const res = await firstValueFrom(
      this.faceService.extractEmbedding({
        image_bytes: imageBuffer,
        bbox: bbox
          ? {
              x: bbox.x,
              y: bbox.y,
              width: bbox.width,
              height: bbox.height,
              confidence: bbox.confidence,
            }
          : undefined,
        landmarks: landmarks?.points?.length
          ? landmarks.points.map((p) => ({
              x: p.x,
              y: p.y,
              index: p.index,
            }))
          : undefined,
      }),
    );
    return new FaceEmbedding(res.embedding.values, res.embedding.dimension);
  }

  // 3. Kiểm tra chống giả mạo
  async checkLiveness(imageBuffer: Buffer): Promise<LivenessResult> {
    const res = await firstValueFrom(
      this.faceService.checkLiveness({ image_bytes: imageBuffer }),
    );
    const statusMap = [
      LivenessStatus.UNKNOWN,
      LivenessStatus.REAL,
      LivenessStatus.SPOOF,
    ];
    const status = statusMap[res.status] ?? LivenessStatus.UNKNOWN;

    return LivenessResult.create(randomUUID(), status, res.confidence, null);
  }

  // 4. So khớp khuôn mặt
  async verify(
    imageBuffer: Buffer,
    referenceEmbedding: FaceEmbedding,
    threshold = 0.68,
  ): Promise<{ matched: boolean; similarity: number }> {
    const res = await firstValueFrom(
      this.faceService.verifyFace({
        image_bytes: imageBuffer,
        reference_embedding: {
          values: referenceEmbedding.values,
          dimension: referenceEmbedding.dimension,
        },
        threshold,
      }),
    );
    return { matched: res.matched, similarity: res.similarity };
  }
}
