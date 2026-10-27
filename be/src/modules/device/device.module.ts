import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Gate } from './domain/entities/gate.entity';
import { Device } from './domain/entities/device.entity';
import { DeviceService } from './application/services/device.service';
import { DeviceController } from './infra/controllers/device.controller';
import { User } from '../user/domain/entities/user.entity';
import { GateService } from './application/services/gate.service';
import { GateController } from './infra/controllers/gate.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Device, Gate, User])],
  controllers: [DeviceController, GateController],
  providers: [DeviceService, GateService],
  exports: [TypeOrmModule, DeviceService],
})
export class DeviceModule {}
