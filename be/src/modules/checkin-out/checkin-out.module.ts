import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AccessLog } from '../access/domain/entities/access-log.entity';
import { Device } from '../device/domain/entities/device.entity';
import { Gate } from '../device/domain/entities/gate.entity';
import { QrToken } from '../qr/domain/entities/qr-token.entity';
import { User } from '../user/domain/entities/user.entity';
import { FaceBiometricModule } from '../biommetric/face-biometric/facebiometric.module';
import { CheckInOutService } from './application/services/checkin-out.service';
import { AccessStateService } from './application/services/access-state.service';
import { CheckInOutController } from './infra/controllers/checkin-out.controller';
import { EventModule } from '../infra/event/event.module';
import { LibraryModule } from '../library/library.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, QrToken, Device, Gate, AccessLog]),
    FaceBiometricModule,
    EventModule,
    LibraryModule,
  ],
  controllers: [CheckInOutController],
  providers: [CheckInOutService, AccessStateService],
  exports: [CheckInOutService, AccessStateService],
})
export class CheckInOutModule {}
