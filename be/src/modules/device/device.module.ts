import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Gate } from './domain/entities/gate.entity';
import { DeviceAssignment } from './domain/entities/device-assignment.entity';
import { DeviceService } from './application/services/device.service';
import { DeviceController } from './infra/controllers/device.controller';
import { Staff } from '../user/domain/entities/staff.entity';

@Module({
  imports: [TypeOrmModule.forFeature([DeviceAssignment, Gate, Staff])],
  controllers: [DeviceController],
  providers: [DeviceService],
  exports: [TypeOrmModule],
})
export class DeviceModule {}
