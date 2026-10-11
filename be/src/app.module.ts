import { BiometricModule } from './modules/biommetric/biometric.module';
import { AuthModule } from './modules/auth/auth.module';
import { UserModule } from './modules/user/user.module';
import { InfrastructureModule } from './modules/infra/infrastructure.module';
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { QrModule } from './modules/qr/qr.module';

@Module({
  imports: [
    BiometricModule,
    ConfigModule.forRoot({ isGlobal: true }),
    AuthModule,
    InfrastructureModule,
    UserModule,
    QrModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
