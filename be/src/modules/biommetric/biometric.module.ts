/*
https://docs.nestjs.com/modules
*/

import { Module } from '@nestjs/common';
import { FaceBiometricModule } from './face-biometric/facebiometric.module';

@Module({
  imports: [FaceBiometricModule],
  controllers: [],
  providers: [FaceBiometricModule],
})
export class BiometricModule {}
