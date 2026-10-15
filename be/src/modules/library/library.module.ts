import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { LibrarySchedule } from './domain/entities/library-schedule.entity';
import { ScheduleService } from './application/services/schedule.service';
import { ScheduleController } from './infra/controllers/schedule.controller';

@Module({
  imports: [TypeOrmModule.forFeature([LibrarySchedule])],
  controllers: [ScheduleController],
  providers: [ScheduleService],
  exports: [ScheduleService],
})
export class LibraryModule {}
