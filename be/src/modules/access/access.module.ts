import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AccessLog } from './domain/entities/access-log.entity';
import { User } from '../user/domain/entities/user.entity';
import { Device } from '../device/domain/entities/device.entity';
import { Gate } from '../device/domain/entities/gate.entity';
import { LibrarySchedule } from '../library/domain/entities/library-schedule.entity';
import { AccessService } from './application/services/access.service';
import { AccessController } from './infra/controllers/access.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([AccessLog, User, Device, Gate, LibrarySchedule]),
  ],
  controllers: [AccessController],
  providers: [AccessService],
  exports: [TypeOrmModule, AccessService],
})
export class AccessModule {}
