import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Gate } from './domain/entities/gate.entity';
import { Device } from './domain/entities/device.entity';
import { DeviceService } from './application/services/device.service';
import { DeviceController } from './infra/controllers/device.controller';
import { User } from '../user/domain/entities/user.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Device, Gate, User])],
  controllers: [DeviceController],
  providers: [DeviceService],
  exports: [TypeOrmModule, DeviceService],
})
export class DeviceModule {}
