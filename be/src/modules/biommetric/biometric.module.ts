/*
https://docs.nestjs.com/modules
*/

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BiometricProfile } from './domain/entities/biometric-profile.entity';
import { BiometricLog } from './domain/entities/biometric-log.entity';
import { FaceBiometricModule } from './face-biometric/facebiometric.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([BiometricProfile, BiometricLog]),
    FaceBiometricModule,
  ],
  controllers: [],
  providers: [FaceBiometricModule],
  exports: [TypeOrmModule, FaceBiometricModule],
})
export class BiometricModule {}
