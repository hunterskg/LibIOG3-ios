import { Module } from '@nestjs/common';
import { CheckInOutController } from './infra/controllers/checkin-out.controller';
import { CheckInOutService } from './application/services/checkin-out.service';

@Module({
  imports: [],
  controllers: [CheckInOutController],
  providers: [CheckInOutService],
  exports: [CheckInOutService],
})
export class CheckInOutModule {}
