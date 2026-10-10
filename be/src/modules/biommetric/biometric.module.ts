/*
https://docs.nestjs.com/modules
*/

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BiometricProfile } from './domain/entities/biometric-profile.entity';
import { BiometricLog } from './domain/entities/biometric-log.entity';

@Module({
  imports: [TypeOrmModule.forFeature([BiometricProfile, BiometricLog])],
  controllers: [],
  providers: [],
  exports: [TypeOrmModule],
})
export class BiometricModule {}
