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

  @ApiProperty({ enum: DeviceStatus })
  status!: DeviceStatus;

  @ApiPropertyOptional()
  deviceFingerprint?: string;

  @ApiPropertyOptional()
  deviceName?: string;

  @ApiPropertyOptional()
  devicePlatform?: string;

  @ApiPropertyOptional()
  expiresAt?: Date;

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
    response.gateId = device.gateId;
    response.status = device.status;
    response.deviceFingerprint = device.deviceFingerprint ?? undefined;
    response.deviceName = device.deviceName;
    response.devicePlatform = device.devicePlatform ?? undefined;
    response.expiresAt = device.expiredAt ?? undefined;
    response.activatedAt = device.activatedAt ?? undefined;
    response.revokedAt = device.revokedAt ?? undefined;
    response.createdAt = device.createdAt;
    return response;
  }
}

export class AssignDeviceRes {
  @ApiProperty({ type: () => DeviceAssignmentRes })
  assignment!: DeviceAssignmentRes;

  @ApiProperty({ example: '482913' })
  activationCode!: string;
}

export class ActivateDeviceRes {
  @ApiProperty({ example: 'Device activated successfully' })
  message!: string;

  @ApiProperty({ type: () => DeviceAssignmentRes })
  assignment!: DeviceAssignmentRes;
}

export { DeviceAssignmentRes as DeviceRes };
