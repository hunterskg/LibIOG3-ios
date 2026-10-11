/*
https://docs.nestjs.com/providers#services
*/

import { Inject, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';
import {
  CACHE_SERVICE,
  CacheService,
} from '../../../../infra/cache/application/interface/cache-service.interface';
import { CheckLivenessService } from './check-liveness.service';
import { DetectFaceService } from './detect-face.service';
import { ExtractEmbeddingService } from './extract-embedding.service';
import { FaceNotFoundException } from '../../domain/exceptions/face-not-found.exception';
import { SpoofDetectedException } from '../../domain/exceptions/spoof-detected.exception';
import { RegisterFaceUseCase } from '../usecases/register-face.usecase';
import { FaceEmbeddingRes, RegisterFaceRes } from '../../dtos/res.dto';
import { RegisterFaceReq } from '../../dtos/req.dto';
import { BiometricProfile } from '../../../domain/entities/biometric-profile.entity';
import { BiometricStatus } from '../../../domain/enums/biometric-status.enum';
import { VectorUtils } from '../../../../../common/utils/vector.utils';
import { DEFAULT_CACHE_TTL_SECONDS } from '../../../../infra/cache/constant';
import { FaceProfile } from '../../domain/entities/face-profile.entity';
import { FacePoseStatus } from '../../domain/enums/face-pose-status.enum';

@Injectable()
export class FaceBiometricService implements RegisterFaceUseCase {
  private static readonly REQUIRED_POSES: readonly FacePoseStatus[] = [
    FacePoseStatus.FRONTAL,
    FacePoseStatus.LEFT_PROFILE,
    FacePoseStatus.RIGHT_PROFILE,
    FacePoseStatus.LOOK_DOWN,
    FacePoseStatus.LOOK_UP,
  ];

  constructor(
    private readonly checkLivenessService: CheckLivenessService,
    private readonly detectFaceService: DetectFaceService,
    private readonly extractEmbeddingService: ExtractEmbeddingService,
    @InjectRepository(BiometricProfile)
    private readonly biometricProfileRepository: Repository<BiometricProfile>,
    @InjectRepository(FaceProfile)
    private readonly faceProfileRepository: Repository<FaceProfile>,
    @Inject(CACHE_SERVICE)
    private readonly cacheService: CacheService,
    private readonly dataSource: DataSource,
  ) {}

  private getRegisterFaceCacheKey(readerId: string, requestId: string): string {
    return `biometric:register:${readerId}:${requestId}`;
  }

  private isFinishedRegistering(cachedData: FaceEmbeddingRes[]): boolean {
    const poses = new Set(cachedData.map((item) => item.pose));
    return FaceBiometricService.REQUIRED_POSES.every((pose) => poses.has(pose));
  }

  async registerFace(
    imageBuffer: Buffer,
    req: RegisterFaceReq,
  ): Promise<RegisterFaceRes> {
    const sessionKey = this.getRegisterFaceCacheKey(
      req.readerId,
      req.requestId,
    );

    const cachedData =
      await this.cacheService.get<FaceEmbeddingRes[]>(sessionKey);

    if (cachedData && cachedData.length > 0) {
      return RegisterFaceRes.of('RegistrationSuccess', req.requestId);
    }

    const maxFaces = 1; // Only allow one face for registration

    // 1. Detect face
    const [faceDetected] = await this.detectFaceService.execute(
      imageBuffer,
      maxFaces,
    );

    if (!faceDetected) {
      throw new FaceNotFoundException('No face detected in the image');
    }

    // 2. Check liveness (spoof check)
    const livenessRes = await this.checkLivenessService.execute(imageBuffer);

    if (livenessRes.isSpoof()) {
      throw new SpoofDetectedException(
        'Face detected but failed liveness check.',
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

    // 4. Cache embedding (append to session list)

    const cachedList = cachedData || [];
    cachedList.push(FaceEmbeddingRes.of(embedding, req.facePose));
    await this.cacheService.set(
      sessionKey,
      cachedList,
      DEFAULT_CACHE_TTL_SECONDS,
    );

    if (!this.isFinishedRegistering(cachedList)) {
      return RegisterFaceRes.of('RegistrationInProgress', req.requestId);
    }

    // 5. Calculate average vector (mean embedding)
    const meanEmbedding = VectorUtils.average(
      cachedList.map((item) => item.values),
    );

    // 6. Save biometric profile to Database
    await this.dataSource.transaction(async (manager) => {
      let profile = await manager.findOne(BiometricProfile, {
        where: { readerId: req.readerId },
      });

      if (!profile) {
        profile = BiometricProfile.create(
          req.readerId,
          'face-detection',
          true,
          new Date(),
          BiometricStatus.ACTIVE,
        );
        profile = await manager.save(profile);
      }

      const faceProfile = FaceProfile.create(
        req.requestId,
        meanEmbedding,
        profile.id,
        profile,
      );
      await manager.save(faceProfile);

      return profile;
    });

    // 7. Delete session cache
    await this.cacheService.del(sessionKey);

    // 8. Return RegistrationSuccess
    return RegisterFaceRes.of('RegistrationSuccess', req.requestId);
  }
}
