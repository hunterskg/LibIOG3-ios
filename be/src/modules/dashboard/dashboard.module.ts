/*
https://docs.nestjs.com/modules
*/

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LibraryModule } from '../library/library.module';
import { AccessLog } from '../access/domain/entities/access-log.entity';
import { DashboardService } from './application/services/dashboard.service';

@Module({
  imports: [LibraryModule, TypeOrmModule.forFeature([AccessLog])],
  controllers: [],
  providers: [DashboardService],
  exports: [DashboardService],
})
export class DashboardModule {}
