import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  Matches,
} from 'class-validator';
import { DeviceStatus } from '../enums/device-status.enum';

export class AssignDeviceReq {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  staffId!: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  gateId!: string;

  @ApiPropertyOptional({ example: 'Staff Mobile Device' })
  @IsString()
  @IsOptional()
  deviceName?: string;
}

export class ActivateDeviceReq {
  @ApiProperty({ example: '482913' })
  @IsString()
  @Length(6, 6)
  @Matches(/^\d{6}$/)
  activationCode!: string;

  @ApiProperty({ example: 'android-3f1b8b9d' })
  @IsString()
  @IsNotEmpty()
  deviceFingerprint!: string;

  @ApiPropertyOptional({ example: 'Samsung Galaxy S24' })
  @IsString()
  @IsOptional()
  deviceName?: string;

  @ApiPropertyOptional({ example: 'android' })
  @IsString()
  @IsOptional()
  devicePlatform?: string;
}

export class QueryAssignmentReq {
  @ApiPropertyOptional({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  @IsOptional()
  staffId?: string;

  @ApiPropertyOptional({ enum: DeviceStatus })
  @IsEnum(DeviceStatus)
  @IsOptional()
  status?: DeviceStatus;
}
