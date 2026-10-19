import { Injectable, UnauthorizedException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BiometricProfile } from '../../../domain/entities/biometric-profile.entity';
import { BiometricStatus } from '../../../domain/enums/biometric-status.enum';
import { FaceProfile } from '../../domain/entities/face-profile.entity';
import { DetectFaceService } from './detect-face.service';
import { CheckLivenessService } from './check-liveness.service';
import { ExtractEmbeddingService } from './extract-embedding.service';
import { FaceNotFoundException } from '../../domain/exceptions/face-not-found.exception';
import { SpoofDetectedException } from '../../domain/exceptions/spoof-detected.exception';

export interface IdentifyFaceResult {
  readerId: string;
  biometricProfileId: string;
  similarity: number;
}

@Injectable()
export class IdentifyFaceService {
  private readonly matchThreshold = 0.55;

  constructor(
    private readonly detectFaceService: DetectFaceService,
    private readonly checkLivenessService: CheckLivenessService,
    private readonly extractEmbeddingService: ExtractEmbeddingService,
    @InjectRepository(FaceProfile)
    private readonly faceProfileRepository: Repository<FaceProfile>,
    @InjectRepository(BiometricProfile)
    private readonly biometricProfileRepository: Repository<BiometricProfile>,
  ) {}

  async execute(imageBuffer: Buffer): Promise<IdentifyFaceResult> {
    if (!imageBuffer || imageBuffer.length === 0) {
      throw new UnauthorizedException('Ảnh khuôn mặt không hợp lệ');
    }

    const faces = await this.detectFaceService.execute(imageBuffer, 1);

    if (faces.length === 0) {
      throw new FaceNotFoundException('Không phát hiện khuôn mặt');
    }

    const liveness = await this.checkLivenessService.execute(imageBuffer);

    if (liveness.isSpoof()) {
      throw new SpoofDetectedException(
        'Khuôn mặt không vượt qua kiểm tra chống giả mạo',
      );
    }

    const detectedFace = faces[0];

    const candidate = await this.extractEmbeddingService.execute(
      imageBuffer,
      detectedFace.bbox,
      detectedFace.landmarks,
      true,
      true,
    );

    const rows: Array<{
      readerId: string;
      biometricProfileId: string;
      similarity: number | string;
    }> = await this.faceProfileRepository.query(
      `
        SELECT
          bp.reader_id AS "readerId",
          bp.id AS "biometricProfileId",
          1 - (fp.embedding <=> $1::vector) AS similarity
        FROM face_profiles fp
        INNER JOIN biometric_profiles bp
          ON bp.id = fp.biometric_profile_id
        WHERE bp.status = $2
          AND bp.consent_given = TRUE
          AND bp.consent_revoked_at IS NULL
        ORDER BY fp.embedding <=> $1::vector
        LIMIT 1
      `,
      [`[${candidate.asVector().join(',')}]`, BiometricStatus.ACTIVE],
    );

    if (!rows.length) {
      throw new UnauthorizedException(
        'Không tìm thấy khuôn mặt đã đăng ký hợp lệ',
      );
    }

    const match = rows[0];
    const similarity = Number(match.similarity);

    if (!Number.isFinite(similarity) || similarity < this.matchThreshold) {
      throw new UnauthorizedException(
        'Khuôn mặt không khớp với hồ sơ đã đăng ký',
      );
    }

    const profile = await this.biometricProfileRepository.findOne({
      where: {
        id: match.biometricProfileId,
        readerId: match.readerId,
        status: BiometricStatus.ACTIVE,
        consentGiven: true,
      },
    });

    if (!profile || !profile.isActive()) {
      throw new UnauthorizedException(
        'Hồ sơ sinh trắc học không hoạt động hoặc đã thu hồi consent',
      );
    }

    return {
      readerId: profile.readerId,
      biometricProfileId: profile.id,
      similarity,
    };
  }
}
