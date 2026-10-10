import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AccessLog } from './domain/entities/access-log.entity';

@Module({
  imports: [TypeOrmModule.forFeature([AccessLog])],
  exports: [TypeOrmModule],
})
export class AccessModule {}
