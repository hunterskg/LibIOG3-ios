import { ApiProperty } from '@nestjs/swagger';
import { CapacityStatus } from '../domain/enums/capacity-status.enum';

export class CheckInOutDashboardRes {
  @ApiProperty({ description: 'Thời điểm bắt đầu bucket' })
  startDate!: Date;

  @ApiProperty({ description: 'Độ dài bucket (phút)' })
  intervalMin!: number;

  @ApiProperty({ description: 'Số lượt check-in thành công trong bucket' })
  checkInCount!: number;

  @ApiProperty({
    description: 'Số lượt check-out (gồm cả auto-checkout) trong bucket',
  })
  checkOutCount!: number;

  @ApiProperty({ description: 'Số người cao nhất có mặt trong bucket' })
  peakPeopleCount!: number;

  @ApiProperty({ description: 'Số người thấp nhất có mặt trong bucket' })
  lowestPeopleCount!: number;
}

export class OccupancyDashboardRes {
  @ApiProperty({
    description: 'Số người hiện tại đang ở trong thư viện',
    example: 142,
  })
  currentOccupants!: number;

  @ApiProperty({ description: 'Sức chứa tối đa của thư viện', example: 500 })
  maxCapacity!: number;

  @ApiProperty({ description: 'Tỷ lệ lấp đầy (%)', example: 28.4 })
  occupancyRate!: number;

  @ApiProperty({
    description: 'Trạng thái sức chứa',
    enum: CapacityStatus,
    example: CapacityStatus.NORMAL,
  })
  status!: CapacityStatus;

  @ApiProperty({ description: 'Thời điểm dữ liệu được cập nhật' })
  updatedAt!: Date;
}
