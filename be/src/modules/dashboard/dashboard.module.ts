import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LibraryModule } from '../library/library.module';
import { AccessLog } from '../access/domain/entities/access-log.entity';
import { DashboardService } from './application/services/dashboard.service';
import { DashboardController } from './infra/controllers/dashboard.controller';

@Module({
  imports: [LibraryModule, ConfigModule, TypeOrmModule.forFeature([AccessLog])],
  controllers: [DashboardController],
  providers: [DashboardService],
  exports: [DashboardService],
})
export class DashboardModule {}
