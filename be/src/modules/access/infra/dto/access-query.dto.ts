import {
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';
import { Type } from 'class-transformer';
import { AccessAction } from '../../domain/enums/access-action.enum';
import { AccessMethod } from '../../domain/enums/access-method.enum';
import { AccessResult } from '../../domain/enums/access-result.enum';

export class QueryAccessLogsDto {
  @IsOptional()
  @Type(() => Number)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  size?: number = 20;

  @IsOptional()
  @IsEnum(AccessAction)
  action?: AccessAction;

  @IsOptional()
  @IsEnum(AccessMethod)
  method?: AccessMethod;

  @IsOptional()
  @IsEnum(AccessResult)
  result?: AccessResult;

  @IsOptional()
  @IsUUID('4')
  readerId?: string;

  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @IsString()
  from?: string;

  @IsOptional()
  @IsString()
  to?: string;
}

export class TriggerClosureDto {
  @IsOptional()
  @IsString()
  @MaxLength(255)
  reason?: string;

  @IsOptional()
  @IsBoolean()
  markTodayClosed?: boolean;
}

export class ReportSummaryQueryDto {
  @IsOptional()
  @IsString()
  from?: string;

  @IsOptional()
  @IsString()
  to?: string;
}
