import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { DeviceStatus } from '../enums/device-status.enum';
import { Device } from '../entities/device.entity';

export class DeviceAssignmentRes {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  staffId!: string;

  @ApiPropertyOptional()
  gateId?: string;

  @ApiPropertyOptional()
  gateCode?: string;

  @ApiPropertyOptional()
  gateName?: string;

  @ApiProperty({ enum: DeviceStatus })
  status!: DeviceStatus;

  @ApiPropertyOptional()
  deviceFingerprint?: string;

  @ApiPropertyOptional()
  deviceName?: string;

  @ApiPropertyOptional()
  devicePlatform?: string;

  @ApiPropertyOptional()
  activatedAt?: Date;

  @ApiPropertyOptional()
  revokedAt?: Date;

  @ApiProperty()
  createdAt!: Date;

  static of(device: Device): DeviceAssignmentRes {
    const response = new DeviceAssignmentRes();
    response.id = device.id;
    response.staffId = device.staffId;
    response.gateId = device.gateId ?? undefined;
    response.gateCode = device.gate?.code;
    response.gateName = device.gate?.name;
    response.status = device.status;
    response.deviceFingerprint = device.deviceFingerprint ?? undefined;
    response.deviceName = device.deviceName;
    response.devicePlatform = device.devicePlatform ?? undefined;
    response.activatedAt = device.activatedAt ?? undefined;
    response.revokedAt = device.revokedAt ?? undefined;
    response.createdAt = device.createdAt;
    return response;
  }
}

export { DeviceAssignmentRes as DeviceRes };
