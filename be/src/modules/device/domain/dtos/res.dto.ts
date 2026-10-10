import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AssignmentStatus } from '../enums/assignment-status.enum';
import { DeviceAssignment } from '../entities/device-assignment.entity';

export class DeviceAssignmentRes {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  staffId!: string;

  @ApiProperty({ enum: AssignmentStatus })
  status!: AssignmentStatus;

  @ApiPropertyOptional()
  deviceFingerprint?: string;

  @ApiPropertyOptional()
  deviceName?: string;

  @ApiPropertyOptional()
  devicePlatform?: string;

  @ApiProperty()
  expiresAt!: Date;

  @ApiPropertyOptional()
  activatedAt?: Date;

  @ApiPropertyOptional()
  revokedAt?: Date;

  @ApiProperty()
  createdAt!: Date;

  static of(assignment: DeviceAssignment): DeviceAssignmentRes {
    const response = new DeviceAssignmentRes();
    response.id = assignment.id;
    response.staffId = assignment.staffId;
    response.status = assignment.status;
    response.deviceFingerprint = assignment.deviceFingerprint;
    response.deviceName = assignment.deviceName;
    response.devicePlatform = assignment.devicePlatform;
    response.expiresAt = assignment.expiresAt;
    response.activatedAt = assignment.activatedAt;
    response.revokedAt = assignment.revokedAt;
    response.createdAt = assignment.createdAt;
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
