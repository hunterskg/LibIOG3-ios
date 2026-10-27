import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
} from 'class-validator';
import { GateStatus } from '../enums/gate-status.enum';
import { Gate } from '../entities/gate.entity';

export class CreateGateReq {
  @ApiProperty({ example: 'GATE-01' })
  @IsString()
  @IsNotEmpty()
  code!: string;

  @ApiProperty({ example: 'Cổng chính' })
  @IsString()
  @IsNotEmpty()
  name!: string;

  @ApiPropertyOptional({ example: 'Tầng 1' })
  @IsString()
  @IsOptional()
  location?: string;
}

export class UpdateGateReq {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  location?: string;

  @ApiPropertyOptional({ enum: GateStatus })
  @IsEnum(GateStatus)
  @IsOptional()
  status?: GateStatus;
}

export class AssignGateReq {
  @ApiProperty()
  @IsUUID()
  gateId!: string;
}

export class GateRes {
  id!: string;
  code!: string;
  name!: string;
  location?: string;
  status!: GateStatus;
  createdAt!: Date;
  updatedAt!: Date;

  static of(gate: Gate): GateRes {
    const result = new GateRes();
    Object.assign(result, gate);
    return result;
  }
}
