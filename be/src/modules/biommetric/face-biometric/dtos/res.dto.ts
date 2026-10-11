import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { LivenessStatus } from '../domain/enums/liveness-status.enum';
import { Face } from '../domain/entities/face.entity';
import { LivenessResult } from '../domain/entities/liveness-result.entity';
import { FaceEmbedding } from '../domain/value-objects/face-embedding.vo';
import { FacePoseStatus } from '../domain/enums/face-pose-status.enum';
import { BiometricStatus } from '../../domain/enums/biometric-status.enum';

export class BoundingBoxRes {
  @ApiProperty({ example: 0.1 })
  x!: number;

  @ApiProperty({ example: 0.1 })
  y!: number;

  @ApiProperty({ example: 0.3 })
  width!: number;

  @ApiProperty({ example: 0.4 })
  height!: number;

  @ApiProperty({ example: 0.98 })
  confidence!: number;
}

export class Point2DRes {
  @ApiProperty({ example: 0.25 })
  x!: number;

  @ApiProperty({ example: 0.35 })
  y!: number;

  @ApiProperty({ example: 0 })
  index!: number;
}

export class FaceRes {
  @ApiProperty({ example: 'face-1' })
  id!: string;

  @ApiProperty({ type: () => BoundingBoxRes })
  bbox!: BoundingBoxRes;

  @ApiProperty({ example: 0.99 })
  confidence!: number;

  @ApiPropertyOptional({ type: () => [Point2DRes] })
  landmarks?: Point2DRes[] | null;

  @ApiPropertyOptional({ example: '/images/face.jpg' })
  imagePath?: string | null;

  @ApiPropertyOptional({ example: 120.5 })
  blurScore?: number | null;

  @ApiPropertyOptional({ example: 5.2 })
  pitch?: number | null;

  @ApiPropertyOptional({ example: 2.1 })
  yaw?: number | null;

  @ApiPropertyOptional({ example: -1.0 })
  roll?: number | null;

  static fromDomain(face: Face): FaceRes {
    const res = new FaceRes();
    res.id = face.id;
    res.bbox = {
      x: face.bbox.x,
      y: face.bbox.y,
      width: face.bbox.width,
      height: face.bbox.height,
      confidence: face.bbox.confidence,
    };
    res.confidence = face.confidence;
    res.landmarks = face.landmarks
      ? face.landmarks.points.map((p) => ({
          x: p.x,
          y: p.y,
          index: p.index,
        }))
      : null;
    res.imagePath = face.imagePath;
    res.blurScore = face.blurScore;
    res.pitch = face.pose?.pitch ?? null;
    res.yaw = face.pose?.yaw ?? null;
    res.roll = face.pose?.roll ?? null;
    return res;
  }
}

export class CheckLivenessRes {
  @ApiProperty({ example: true })
  isLive!: boolean;

  @ApiProperty({ enum: LivenessStatus, example: LivenessStatus.REAL })
  status!: LivenessStatus;

  @ApiProperty({ example: 0.96 })
  confidence!: number;

  @ApiPropertyOptional()
  details?: Record<string, unknown> | null;

  static fromDomain(result: LivenessResult): CheckLivenessRes {
    const res = new CheckLivenessRes();
    res.isLive = result.isLive();
    res.status = result.status;
    res.confidence = result.confidence;
    res.details = result.details;
    return res;
  }
}

export class ExtractEmbeddingRes {
  @ApiProperty({ type: [Number], example: [0.01, -0.05, 0.12] })
  values!: number[];

  @ApiProperty({ example: 512 })
  dimension!: number;

  static fromDomain(embedding: FaceEmbedding): ExtractEmbeddingRes {
    const res = new ExtractEmbeddingRes();
    res.values = embedding.asVector();
    res.dimension = embedding.dimension;
    return res;
  }
}

export class VerifyFaceRes {
  @ApiProperty({ example: true })
  isMatched!: boolean;

  @ApiProperty({ example: 0.88 })
  similarity!: number;
}

export class FaceEmbeddingRes {
  @ApiProperty({ type: [Number], example: [0.01, -0.05, 0.12] })
  values!: number[];

  @ApiProperty({ example: 512 })
  dimension!: number;

  pose?: FacePoseStatus | null;

  static of(
    embedding: FaceEmbedding,
    pose?: FacePoseStatus | null,
  ): FaceEmbeddingRes {
    const res = new FaceEmbeddingRes();
    res.values = embedding.asVector();
    res.dimension = embedding.dimension;
    res.pose = pose ?? null;
    return res;
  }
}

export class RegisterFaceRes {
  @ApiProperty({ example: 'face-1' })
  message!: string;

  @ApiProperty({ example: 'result-1' })
  resultId!: string;

  static of(message: string, resultId: string): RegisterFaceRes {
    const res = new RegisterFaceRes();
    res.message = message;
    res.resultId = resultId;
    return res;
  }
}

export class FaceRegistrationStatusRes {
  @ApiProperty({
    description: 'Trạng thái đã đăng ký khuôn mặt hợp lệ hay chưa',
    example: true,
  })
  isRegistered!: boolean;

  @ApiPropertyOptional({
    enum: BiometricStatus,
    description: 'Trạng thái hồ sơ sinh trắc học',
    example: BiometricStatus.ACTIVE,
  })
  status?: BiometricStatus;

  @ApiPropertyOptional({
    description: 'Thời điểm đăng ký hoặc cấp phép sinh trắc học',
    example: '2026-10-11T12:00:00.000Z',
  })
  registeredAt?: Date;

  @ApiPropertyOptional({
    description: 'Thời điểm cập nhật dữ liệu khuôn mặt gần nhất',
    example: '2026-10-11T12:00:00.000Z',
  })
  updatedAt?: Date;

  static notRegistered(): FaceRegistrationStatusRes {
    const res = new FaceRegistrationStatusRes();
    res.isRegistered = false;
    return res;
  }

  static registered(
    status: BiometricStatus,
    registeredAt?: Date,
    updatedAt?: Date,
  ): FaceRegistrationStatusRes {
    const res = new FaceRegistrationStatusRes();
    res.isRegistered = status === BiometricStatus.ACTIVE;
    res.status = status;
    res.registeredAt = registeredAt;
    res.updatedAt = updatedAt;
    return res;
  }
}
