import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsDateString, IsInt, IsOptional, Max, Min } from 'class-validator';

export class CheckInOutDashboardReq {
  @ApiProperty({
    description: 'Thời điểm bắt đầu (ISO8601)',
    example: '2026-10-20T00:00:00.000Z',
  })
  @IsDateString()
  startDate!: string | Date;

  @ApiProperty({
    description: 'Thời điểm kết thúc (ISO8601)',
    example: '2026-10-27T23:59:59.999Z',
  })
  @IsDateString()
  endDate!: string | Date;

  @ApiPropertyOptional({
    description: 'Bước khoảng thời gian tính bằng phút (15, 30, 60, 1440)',
    default: 60,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(43200)
  intervalMin: number = 60;
}
