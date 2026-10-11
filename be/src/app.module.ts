import { BiometricModule } from './modules/biommetric/biometric.module';
import { AuthModule } from './modules/auth/auth.module';
import { UserModule } from './modules/user/user.module';
import { InfrastructureModule } from './modules/infra/infrastructure.module';
import { DeviceModule } from './modules/device/device.module';
import { AccessModule } from './modules/access/access.module';
import { NotificationModule } from './modules/notification/notification.module';
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';

@Module({
  imports: [
    BiometricModule,
    ConfigModule.forRoot({ isGlobal: true }),
    AuthModule,
    InfrastructureModule,
    UserModule,
    DeviceModule,
    AccessModule,
    NotificationModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
