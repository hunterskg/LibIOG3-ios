import { DashboardModule } from './modules/dashboard/dashboard.module';
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
import { QrModule } from './modules/qr/qr.module';
import { CheckInOutModule } from './modules/checkin-out/checkin-out.module';
import { LibraryModule } from './modules/library/library.module';

@Module({
  imports: [
    DashboardModule,
    BiometricModule,
    ConfigModule.forRoot({ isGlobal: true }),
    AuthModule,
    InfrastructureModule,
    UserModule,
    QrModule,
    DeviceModule,
    AccessModule,
    NotificationModule,
    CheckInOutModule,
    LibraryModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
