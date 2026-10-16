import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { join } from 'path';
import { BiometricProfile } from '../domain/entities/biometric-profile.entity';
import { CacheModule } from '../../infra/cache/cache.module';
import { FACE_DETECTOR_PORT } from './application/ports/face-detector.port';
import { FACE_EMBEDDER_PORT } from './application/ports/face-embedder.port';
import { LIVENESS_DETECTOR_PORT } from './application/ports/liveness-detector.port';
import { CheckLivenessService } from './application/services/check-liveness.service';
import { DetectFaceService } from './application/services/detect-face.service';
import { ExtractEmbeddingService } from './application/services/extract-embedding.service';
import { VerifyFaceService } from './application/services/verify-face.service';
import {
  FACE_GRPC_CLIENT,
  FaceGrpcAdapter,
} from './infra/grpc/adapters/face-grpc.adapter';
import { FaceTestController } from './infra/controllers/face-test.controller';
import { FaceBiometricController } from './infra/controllers/face-biometric.controller';
import { FaceDomainExceptionInterceptor } from './infra/interceptors/face-domain-exception.interceptor';
import { FaceBiometricService } from './application/services/facebiometric.service';
import { FaceProfile } from './domain/entities/face-profile.entity';
import { IdentifyFaceService } from './application/services/identify-face.service';
@Module({
  imports: [
    TypeOrmModule.forFeature([BiometricProfile, FaceProfile]),
    CacheModule,
    ClientsModule.register([
      {
        name: FACE_GRPC_CLIENT,
        transport: Transport.GRPC,
        options: {
          package: 'face.v1', // Khớp với "package face.v1;" trong face.proto
          protoPath: join(__dirname, 'infra/proto/face.proto'),
          url: process.env.PYTHON_GRPC_URL || 'localhost:50051',
          loader: {
            keepCase: true,
            longs: String,
            enums: String,
            defaults: true,
            oneofs: true,
          },
        },
      },
    ]),
  ],
  controllers: [FaceTestController, FaceBiometricController],
  providers: [
    FaceGrpcAdapter,
    // Liên kết Port trừu tượng với Adapter gRPC cụ thể
    { provide: FACE_DETECTOR_PORT, useExisting: FaceGrpcAdapter },
    { provide: FACE_EMBEDDER_PORT, useExisting: FaceGrpcAdapter },
    { provide: LIVENESS_DETECTOR_PORT, useExisting: FaceGrpcAdapter },
    CheckLivenessService,
    DetectFaceService,
    ExtractEmbeddingService,
    VerifyFaceService,
    FaceDomainExceptionInterceptor,
    FaceBiometricService,
    IdentifyFaceService,
  ],
  exports: [
    CheckLivenessService,
    DetectFaceService,
    ExtractEmbeddingService,
    VerifyFaceService,
    FaceGrpcAdapter,
    FaceDomainExceptionInterceptor,
    FaceBiometricService,
    IdentifyFaceService,
  ],
})
export class FaceBiometricModule {}
