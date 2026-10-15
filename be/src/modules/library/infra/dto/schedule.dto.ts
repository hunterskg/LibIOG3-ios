import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsISO8601,
  IsOptional,
  IsString,
  Matches,
  Max,
  Min,
} from 'class-validator';

import { ScheduleType } from '../../domain/enums/schedule-type.enum';

// Giờ ở dạng "HH:MM" hoặc "HH:MM:SS".
const TIME_REGEX = /^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/;

export class CreateScheduleDto {
  @IsEnum(ScheduleType)
  type!: ScheduleType;

  // Bắt buộc khi type = WEEKLY. 0 = Chủ nhật ... 6 = Thứ Bảy.
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(6)
  dayOfWeek?: number;

  // Bắt buộc khi type = SPECIAL. Dạng YYYY-MM-DD.
  @IsOptional()
  @IsISO8601()
  specificDate?: string;

  @IsOptional()
  @Matches(TIME_REGEX, { message: 'openTime phải có dạng HH:MM hoặc HH:MM:SS' })
  openTime?: string;

  @IsOptional()
  @Matches(TIME_REGEX, { message: 'closeTime phải có dạng HH:MM hoặc HH:MM:SS' })
  closeTime?: string;

  @IsOptional()
  @IsBoolean()
  isClosed?: boolean;

  @IsOptional()
  @IsString()
  note?: string;
}

// Một ngày trong lưới "giờ hàng tuần".
export class WeeklyDayDto {
  @IsInt()
  @Min(0)
  @Max(6)
  dayOfWeek!: number;

  @IsBoolean()
  isClosed!: boolean;

  @IsOptional()
  @Matches(TIME_REGEX, { message: 'openTime phải có dạng HH:MM hoặc HH:MM:SS' })
  openTime?: string;

  @IsOptional()
  @Matches(TIME_REGEX, { message: 'closeTime phải có dạng HH:MM hoặc HH:MM:SS' })
  closeTime?: string;
}

// Ghi đè toàn bộ lịch hàng tuần trong một lần.
export class SetWeeklyDto {
  @IsArray()
  days!: WeeklyDayDto[];
}

// Tất cả field đều tùy chọn khi cập nhật.
export class UpdateScheduleDto {
  @IsOptional()
  @IsEnum(ScheduleType)
  type?: ScheduleType;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(6)
  dayOfWeek?: number;

  @IsOptional()
  @IsISO8601()
  specificDate?: string;

  @IsOptional()
  @Matches(TIME_REGEX, { message: 'openTime phải có dạng HH:MM hoặc HH:MM:SS' })
  openTime?: string;

  @IsOptional()
  @Matches(TIME_REGEX, { message: 'closeTime phải có dạng HH:MM hoặc HH:MM:SS' })
  closeTime?: string;

  @IsOptional()
  @IsBoolean()
  isClosed?: boolean;

  @IsOptional()
  @IsString()
  note?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
